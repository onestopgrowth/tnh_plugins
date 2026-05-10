# frozen_string_literal: true

# name: tnhiq-podcast
# about: Auto-ingest Truck N' Hustle podcast episodes from RSS into Discourse topics with niche routing
# version: 0.1.0
# authors: TNHIQ
# url: https://github.com/onestopgrowth/tnh-community-backend

enabled_site_setting :tnhiq_podcast_enabled

after_initialize do
  require_relative "app/models/tnhiq_podcast/ingested_episode"
  require_relative "lib/tnhiq_podcast/category_router"
  require_relative "lib/tnhiq_podcast/rss_fetcher"
  require_relative "lib/tnhiq_podcast/episode_ingester"
  require_relative "app/jobs/scheduled/tnhiq_podcast_poll"
  require_relative "app/controllers/tnhiq_podcast/admin_controller"

  Discourse::Application.routes.append do
    scope "/admin/plugins/tnhiq-podcast", constraints: AdminConstraint.new do
      get  "/dashboard"  => "tnhiq_podcast/admin#index"
      post "/poll-now"   => "tnhiq_podcast/admin#poll_now"
      post "/ingest-one" => "tnhiq_podcast/admin#ingest_one"
    end
  end
end
