# frozen_string_literal: true

module ::TnhiqSponsors
  class PlacementsController < ::ApplicationController
    requires_plugin "tnhiq-sponsors"

    skip_before_action :check_xhr

    before_action :ensure_logged_in
    before_action :ensure_admin_or_staff, only: %i[index create update destroy clicks]

    PERMITTED_ATTRS = %i[
      slot sponsor_name sponsor_logo_url sponsor_link cta_text
      target_niche target_group_id category_id active starts_at ends_at
    ].freeze

    # GET /sponsor-placements/active?slot=X&category_id=Y
    # Returns the best matching active placement for the current user, or null.
    def active
      slot = params[:slot].to_s
      return render json: { error: "missing_slot" }, status: 400 if slot.empty?

      placement = ::TnhiqSponsors::Resolver.resolve(
        slot:        slot,
        user:        current_user,
        category_id: params[:category_id].presence&.to_i,
      )

      render json: placement && placement_payload(placement).merge(
        click_url: build_click_url(placement, params[:page_url]),
      )
    end

    # Admin: GET /admin/plugins/tnhiq-sponsors/data
    def index
      placements =
        ::TnhiqSponsors::Placement
          .order(active: :desc, created_at: :desc)
          .includes(:clicks)
          .map { |p| placement_payload(p).merge(click_count: p.click_count) }
      render json: { placements: placements }
    end

    # Admin: POST /admin/plugins/tnhiq-sponsors
    def create
      attrs = params.permit(*PERMITTED_ATTRS).to_h
      placement = ::TnhiqSponsors::Placement.new(attrs)
      if placement.save
        render json: placement_payload(placement), status: 201
      else
        render json: { errors: placement.errors.full_messages }, status: 422
      end
    rescue ActiveRecord::RecordNotUnique
      render json: { errors: ["A category may only have one active placement per slot."] }, status: 409
    end

    # Admin: PATCH /admin/plugins/tnhiq-sponsors/:id
    def update
      placement = ::TnhiqSponsors::Placement.find_by(id: params[:id])
      raise ::Discourse::NotFound unless placement

      attrs = params.permit(*PERMITTED_ATTRS).to_h
      if placement.update(attrs)
        render json: placement_payload(placement)
      else
        render json: { errors: placement.errors.full_messages }, status: 422
      end
    rescue ActiveRecord::RecordNotUnique
      render json: { errors: ["A category may only have one active placement per slot."] }, status: 409
    end

    # Admin: DELETE /admin/plugins/tnhiq-sponsors/:id
    def destroy
      placement = ::TnhiqSponsors::Placement.find_by(id: params[:id])
      raise ::Discourse::NotFound unless placement
      placement.destroy
      render json: { ok: true }
    end

    # Admin: GET /admin/plugins/tnhiq-sponsors/:id/clicks
    def clicks
      placement = ::TnhiqSponsors::Placement.find_by(id: params[:id])
      raise ::Discourse::NotFound unless placement

      rows = placement.clicks.order(clicked_at: :desc).limit(500).pluck(
        :id, :user_id, :clicked_at, :page_url, :ip_address,
      )
      render json: {
        placement_id: placement.id,
        sponsor_name: placement.sponsor_name,
        total_clicks: placement.click_count,
        clicks: rows.map { |id, uid, ts, url, ip|
          { id: id, user_id: uid, clicked_at: ts, page_url: url, ip_address: ip }
        },
      }
    end

    private

    def ensure_admin_or_staff
      raise ::Discourse::InvalidAccess unless current_user&.staff?
    end

    def placement_payload(placement)
      placement.as_json(only: %i[
        id slot sponsor_name sponsor_logo_url sponsor_link cta_text
        target_niche target_group_id category_id active starts_at ends_at created_at
      ])
    end

    def build_click_url(placement, page_url)
      query = { placement_id: placement.id }
      query[:page_url] = page_url if page_url.present?
      "/sponsor-click?#{query.to_query}"
    end
  end
end
