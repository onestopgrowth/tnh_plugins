# frozen_string_literal: true

module ::TnhiqOpportunities
  class OpportunitiesController < ::ApplicationController
    requires_plugin "tnhiq-opportunities"

    layout false
    skip_before_action :preload_json, only: %i[index show]
    skip_before_action :check_xhr, only: %i[index show]

    before_action :ensure_logged_in
    before_action :load_opportunity, only: %i[show express_interest withdraw_interest]

    INDEX_TEMPLATE_PATH = File.expand_path(
      "../../views/tnhiq_opportunities/opportunities/index.html.erb",
      __dir__,
    ).freeze

    SHOW_TEMPLATE_PATH = File.expand_path(
      "../../views/tnhiq_opportunities/opportunities/show.html.erb",
      __dir__,
    ).freeze

    def index
      scope = ::TnhiqOpportunities::Opportunity.listable

      # Tier filter — show only opportunities the current user can access.
      user_tier = ::TnhiqOpportunities::TierGate.user_tier(current_user)
      allowed_tiers =
        ::TnhiqOpportunities::TierGate::TIER_ORDER[
          0..::TnhiqOpportunities::TierGate::TIER_ORDER.index(user_tier)
        ]
      scope = scope.where(tier_required: allowed_tiers)

      scope = scope.where(equipment_type: params[:equipment_type]) if params[:equipment_type].present?
      scope = scope.where(origin_state: params[:origin_state].to_s.upcase) if params[:origin_state].present?
      scope = scope.where(destination_state: params[:destination_state].to_s.upcase) if params[:destination_state].present?
      scope = scope.where(commodity: params[:commodity]) if params[:commodity].present?
      scope = scope.where(source_type: params[:source_type]) if params[:source_type].present?

      scope =
        case params[:sort]
        when "expiring_soon" then scope.order(Arel.sql("expires_at IS NULL, expires_at ASC"))
        when "most_interest" then scope.left_joins(:interests).group("tnhiq_opportunities.id").order(Arel.sql("COUNT(tnhiq_opportunity_interests.id) DESC, tnhiq_opportunities.created_at DESC"))
        else scope.order(created_at: :desc)
        end

      page_size = SiteSetting.tnhiq_opportunities_default_page_size.to_i
      page_size = 25 if page_size <= 0
      page = [params[:page].to_i, 1].max

      @opportunities = scope.limit(page_size).offset((page - 1) * page_size)
      @total_count   = scope.except(:order, :group).count
      @page          = page
      @page_size     = page_size
      @user_tier     = user_tier
      @filters       = params.permit(:equipment_type, :origin_state, :destination_state, :commodity, :source_type, :sort).to_h

      respond_to do |format|
        format.html do
          template = File.read(INDEX_TEMPLATE_PATH)
          render inline: template, type: :erb, layout: false
        end
        format.json do
          render json: {
            opportunities: @opportunities.as_json(only: %i[id title equipment_type origin_state destination_state commodity source_type source_label tier_required requires_verified expires_at status external_reference_id created_at]),
            total: @total_count,
            page: @page,
            page_size: @page_size,
            user_tier: @user_tier,
            filters: @filters,
          }
        end
      end
    end

    def show
      unless ::TnhiqOpportunities::TierGate.accessible?(current_user, @opportunity)
        return render_tier_gated
      end

      @already_interested = ::TnhiqOpportunities::Interest.exists?(
        opportunity_id: @opportunity.id, user_id: current_user.id,
      )
      @verified = ::TnhiqOpportunities::IqdidGate.verified?(current_user)

      respond_to do |format|
        format.html do
          template = File.read(SHOW_TEMPLATE_PATH)
          render inline: template, type: :erb, layout: false
        end
        format.json do
          render json: opportunity_payload(@opportunity).merge(
            already_interested: @already_interested,
            verified:           @verified,
            interest_blocked:   @opportunity.requires_verified && !@verified,
          )
        end
      end
    end

    def express_interest
      unless ::TnhiqOpportunities::TierGate.accessible?(current_user, @opportunity)
        return render json: { ok: false, error: "tier_required" }, status: 403
      end

      if @opportunity.requires_verified && !::TnhiqOpportunities::IqdidGate.verified?(current_user)
        return render json: { ok: false, error: "verification_required" }, status: 403
      end

      interest = ::TnhiqOpportunities::Interest.find_or_initialize_by(
        opportunity_id: @opportunity.id,
        user_id:        current_user.id,
      )
      interest.notes = params[:notes].to_s if params.key?(:notes)

      if interest.save
        render json: { ok: true, interest_id: interest.id }
      else
        render json: { ok: false, errors: interest.errors.full_messages }, status: 422
      end
    end

    def withdraw_interest
      ::TnhiqOpportunities::Interest
        .where(opportunity_id: @opportunity.id, user_id: current_user.id)
        .destroy_all
      render json: { ok: true }
    end

    private

    def load_opportunity
      @opportunity = ::TnhiqOpportunities::Opportunity.find_by(id: params[:id])
      raise ::Discourse::NotFound unless @opportunity
    end

    def render_tier_gated
      respond_to do |format|
        format.json { render json: { error: "tier_required", required: @opportunity.tier_required }, status: 403 }
        format.html { render plain: "This opportunity is gated to #{@opportunity.tier_required.titleize} members and above.", status: 403, layout: false }
      end
    end

    def opportunity_payload(opp)
      opp.as_json(only: %i[
        id title description equipment_type origin_state destination_state commodity
        source_type source_label tier_required requires_verified expires_at status
        external_reference_id created_at
      ]).merge(interest_count: opp.interest_count)
    end
  end
end
