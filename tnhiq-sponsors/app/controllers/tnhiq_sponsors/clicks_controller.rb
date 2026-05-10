# frozen_string_literal: true

module ::TnhiqSponsors
  class ClicksController < ::ApplicationController
    requires_plugin "tnhiq-sponsors"

    skip_before_action :check_xhr
    skip_before_action :preload_json
    skip_before_action :redirect_to_login_if_required

    # GET /s/click?placement_id=X&page_url=Y
    # Records the click, then 302s to the sponsor's actual link.
    def redirect
      placement_id = params[:placement_id].to_i
      placement = ::TnhiqSponsors::Placement.find_by(id: placement_id) if placement_id.positive?

      unless placement&.active?
        return render plain: "Placement not found.", status: 404, layout: false
      end

      ::TnhiqSponsors::Click.create!(
        placement_id: placement.id,
        user_id:      current_user&.id,
        clicked_at:   Time.current,
        page_url:     params[:page_url].to_s.presence&.first(1024),
        ip_address:   request.remote_ip&.first(64),
        user_agent:   request.user_agent&.first(512),
      )

      target = placement.sponsor_link.to_s
      raise ::Discourse::InvalidAccess unless target.start_with?("http://", "https://")

      redirect_to target, allow_other_host: true, status: 302
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.warn("[tnhiq-sponsors] click record failed: #{e.message}")
      target = placement&.sponsor_link.to_s
      if target.start_with?("http://", "https://")
        redirect_to target, allow_other_host: true, status: 302
      else
        render plain: "Click recording failed.", status: 500, layout: false
      end
    end
  end
end
