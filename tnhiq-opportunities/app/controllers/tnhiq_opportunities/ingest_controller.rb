# frozen_string_literal: true

module ::TnhiqOpportunities
  # Inbound webhook for the external load-board project. Authenticated by a
  # shared bearer token in the SiteSetting `tnhiq_opportunities_ingest_secret`.
  class IngestController < ::ApplicationController
    requires_plugin "tnhiq-opportunities"

    skip_before_action :verify_authenticity_token
    skip_before_action :preload_json
    skip_before_action :redirect_to_login_if_required
    skip_before_action :check_xhr

    before_action :verify_ingest_secret

    UPSERT_KEYS = %w[
      title description equipment_type origin_state destination_state commodity
      source_type source_label tier_required requires_verified expires_at status
    ].freeze

    def create
      reference = params[:external_reference_id].to_s.strip
      return render json: { ok: false, error: "missing_external_reference_id" }, status: 422 if reference.empty?

      attrs = params.permit(*UPSERT_KEYS).to_h
      attrs["origin_state"] = attrs["origin_state"].to_s.upcase if attrs.key?("origin_state")
      attrs["destination_state"] = attrs["destination_state"].to_s.upcase if attrs.key?("destination_state")

      opp = ::TnhiqOpportunities::Opportunity.find_or_initialize_by(external_reference_id: reference)
      opp.assign_attributes(attrs)
      opp.source_type = "internal" if opp.source_type.blank?
      opp.status = "active" if opp.status.blank?
      opp.tier_required = "free" if opp.tier_required.blank?

      if opp.save
        render json: { ok: true, id: opp.id, created: opp.previously_new_record? }
      else
        render json: { ok: false, errors: opp.errors.full_messages }, status: 422
      end
    end

    private

    def verify_ingest_secret
      expected = SiteSetting.tnhiq_opportunities_ingest_secret.to_s
      if expected.blank?
        return render json: { ok: false, error: "ingest_secret_not_configured" }, status: 503
      end

      header = request.headers["Authorization"].to_s
      provided = header.start_with?("Bearer ") ? header.sub(/\ABearer\s+/, "") : header

      unless ActiveSupport::SecurityUtils.secure_compare(provided, expected)
        render json: { ok: false, error: "unauthorized" }, status: 401
      end
    end
  end
end
