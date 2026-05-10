# frozen_string_literal: true

module ::TnhiqSponsors
  class AdminController < ::ApplicationController
    requires_plugin "tnhiq-sponsors"

    layout false
    skip_before_action :preload_json, only: [:index]
    skip_before_action :check_xhr, only: [:index]

    INDEX_TEMPLATE_PATH = File.expand_path(
      "../../views/tnhiq_sponsors/admin/index.html.erb",
      __dir__,
    ).freeze

    # AdminConstraint already requires admin; guard once more in case it's bypassed.
    before_action :ensure_admin

    def index
      @placements = ::TnhiqSponsors::Placement.order(active: :desc, created_at: :desc).includes(:clicks)
      template = File.read(INDEX_TEMPLATE_PATH)
      render inline: template, type: :erb, layout: false
    end

    private

    def ensure_admin
      raise ::Discourse::InvalidAccess unless current_user&.admin?
    end
  end
end
