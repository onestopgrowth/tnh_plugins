# frozen_string_literal: true

# name: tnhiq-onboarding
# about: Founder's Circle onboarding + member routing for Truck N' Hustle. Collects a short intake on first login for paid members, classifies them into a starting path, stores answers as user custom fields, adds them to the matching path group, and sends them to their recommended next step.
# version: 0.1.0
# authors: TNHIQ
# url: https://github.com/onestopgrowth/tnh_plugins

enabled_site_setting :tnhiq_onboarding_enabled

after_initialize do
  # User custom fields (all answers live on the user profile). Registered here
  # rather than at the top level so the User model is loaded — registering at
  # load time breaks `rake db:migrate` (uninitialized constant User).
  # Multi-selects are stored as JSON; single answers as strings.
  register_user_custom_field_type("tnhiq_onboarding_completed_at", :string)
  register_user_custom_field_type("tnhiq_stage", :string)
  register_user_custom_field_type("tnhiq_interests", :json)
  register_user_custom_field_type("tnhiq_pain_point", :string)
  register_user_custom_field_type("tnhiq_resources", :json)
  register_user_custom_field_type("tnhiq_goal_90_day", :string)
  register_user_custom_field_type("tnhiq_help_wanted", :json)
  register_user_custom_field_type("tnhiq_path", :string)

  require_relative "lib/tnhiq_onboarding/answers"
  require_relative "lib/tnhiq_onboarding/paths"
  require_relative "lib/tnhiq_onboarding/path_assigner"
  require_relative "lib/tnhiq_onboarding/segmenter"
  require_relative "app/controllers/tnhiq_onboarding/onboarding_controller"
  require_relative "app/controllers/tnhiq_onboarding/admin_report_controller"

  Discourse::Application.routes.append do
    get  "/founders/onboarding"        => "tnhiq_onboarding/onboarding#index"
    get  "/founders/onboarding/status" => "tnhiq_onboarding/onboarding#status"
    post "/founders/onboarding/submit" => "tnhiq_onboarding/onboarding#submit"
    get  "/founders/onboarding/result" => "tnhiq_onboarding/onboarding#result"

    scope "/admin/plugins/tnhiq-onboarding", constraints: AdminConstraint.new do
      get "/report" => "tnhiq_onboarding/admin_report#index"
    end
  end
end
