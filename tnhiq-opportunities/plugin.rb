# frozen_string_literal: true

# name: tnhiq-opportunities
# about: Curated opportunity board (loads, partnerships, direct shippers) with tier + IQDID gating
# version: 0.1.0
# authors: TNHIQ
# url: https://github.com/onestopgrowth/tnh-community-backend

enabled_site_setting :tnhiq_opportunities_enabled

after_initialize do
  require_relative "app/models/tnhiq_opportunities/opportunity"
  require_relative "app/models/tnhiq_opportunities/interest"
  require_relative "lib/tnhiq_opportunities/tier_gate"
  require_relative "lib/tnhiq_opportunities/iqdid_gate"
  require_relative "app/controllers/tnhiq_opportunities/opportunities_controller"
  require_relative "app/controllers/tnhiq_opportunities/ingest_controller"

  Discourse::Application.routes.append do
    get  "/opportunities"               => "tnhiq_opportunities/opportunities#index"
    get  "/opportunities/:id"           => "tnhiq_opportunities/opportunities#show", constraints: { id: /\d+/ }
    post "/opportunities/:id/interest"  => "tnhiq_opportunities/opportunities#express_interest", constraints: { id: /\d+/ }
    delete "/opportunities/:id/interest" => "tnhiq_opportunities/opportunities#withdraw_interest", constraints: { id: /\d+/ }

    post "/discourse-plugin/opportunities/ingest" => "tnhiq_opportunities/ingest#create"
  end
end
