# frozen_string_literal: true

# name: tnhiq-sponsors
# about: Sponsor and affiliate placement system with niche/group/category targeting + click tracking
# version: 0.1.0
# authors: TNHIQ
# url: https://github.com/onestopgrowth/tnh-community-backend

enabled_site_setting :tnhiq_sponsors_enabled

after_initialize do
  require_relative "app/models/tnhiq_sponsors/placement"
  require_relative "app/models/tnhiq_sponsors/click"
  require_relative "lib/tnhiq_sponsors/resolver"
  require_relative "app/controllers/tnhiq_sponsors/placements_controller"
  require_relative "app/controllers/tnhiq_sponsors/clicks_controller"
  require_relative "app/controllers/tnhiq_sponsors/admin_controller"

  Discourse::Application.routes.append do
    # Public-facing resolver — used by other plugins/pages to fetch the active sponsor for a slot.
    get "/sponsor-placements/active" => "tnhiq_sponsors/placements#active"

    # Click redirect — public, no auth required. Path avoids /s/* (used by discourse-subscriptions).
    get "/sponsor-click" => "tnhiq_sponsors/clicks#redirect"

    # Admin CRUD. The bare path /admin/plugins/tnhiq-sponsors is reserved by
    # Discourse's plugin metadata viewer, so the HTML dashboard lives at /dashboard.
    scope "/admin/plugins/tnhiq-sponsors", constraints: AdminConstraint.new do
      get    "/dashboard"  => "tnhiq_sponsors/admin#index"
      get    "/data"       => "tnhiq_sponsors/placements#index"
      post   "/placements" => "tnhiq_sponsors/placements#create"
      patch  "/placements/:id" => "tnhiq_sponsors/placements#update", constraints: { id: /\d+/ }
      delete "/placements/:id" => "tnhiq_sponsors/placements#destroy", constraints: { id: /\d+/ }
      get    "/placements/:id/clicks" => "tnhiq_sponsors/placements#clicks", constraints: { id: /\d+/ }
    end
  end
end
