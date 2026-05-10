# frozen_string_literal: true

# name: tnhiq-niche-onboarding
# about: First-login niche onboarding flow + CRM sync to tnh-comm-api
# version: 0.1.0
# authors: TNHIQ
# url: https://github.com/onestopgrowth/tnh-community-backend

enabled_site_setting :tnhiq_niche_onboarding_enabled

after_initialize do
  require_relative "app/models/tnhiq_niche_onboarding/profile"
  require_relative "lib/tnhiq_niche_onboarding/category_subscriber"
  require_relative "lib/tnhiq_niche_onboarding/crm_notifier"
  require_relative "app/controllers/tnhiq_niche_onboarding/onboarding_controller"

  Discourse::Application.routes.append do
    get  "/onboarding"        => "tnhiq_niche_onboarding/onboarding#index"
    get  "/onboarding/status" => "tnhiq_niche_onboarding/onboarding#status"
    post "/onboarding/submit" => "tnhiq_niche_onboarding/onboarding#submit"
  end
end
