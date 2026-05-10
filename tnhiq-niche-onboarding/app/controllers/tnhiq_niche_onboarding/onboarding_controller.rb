# frozen_string_literal: true

module ::TnhiqNicheOnboarding
  class OnboardingController < ::ApplicationController
    requires_plugin "tnhiq-niche-onboarding"

    layout false
    skip_before_action :preload_json, only: [:index]
    skip_before_action :check_xhr, only: [:index]

    before_action :ensure_logged_in

    def use_crawler_layout?
      false
    end

    def ember_cli_required?
      false
    end

    ONBOARDING_TEMPLATE_PATH = File.expand_path(
      "../../views/tnhiq_niche_onboarding/onboarding/index.html.erb",
      __dir__,
    ).freeze

    def index
      profile = ::TnhiqNicheOnboarding::Profile.find_by(user_id: current_user.id)
      return redirect_to "/" if profile.present?

      template = File.read(ONBOARDING_TEMPLATE_PATH)
      render inline: template, type: :erb, layout: false
    end

    def status
      profile = ::TnhiqNicheOnboarding::Profile.find_by(user_id: current_user.id)

      render json: {
        completed: profile.present?,
        profile: profile && {
          niche:        profile.niche,
          equipment:    profile.equipment,
          stage:        profile.stage,
          completed_at: profile.completed_at,
        },
      }
    end

    def submit
      niche     = params[:niche].to_s
      equipment = Array(params[:equipment]).map(&:to_s)
      stage     = params[:stage].to_s

      profile = ::TnhiqNicheOnboarding::Profile.find_or_initialize_by(user_id: current_user.id)
      profile.assign_attributes(
        niche:        niche,
        equipment:    equipment,
        stage:        stage,
        completed_at: Time.current,
      )

      if profile.save
        begin
          ::TnhiqNicheOnboarding::CategorySubscriber.new(current_user, profile.niche).subscribe!
        rescue StandardError => e
          Rails.logger.warn("[tnhiq-niche-onboarding] subscribe failed: #{e.class} #{e.message}")
        end

        ::TnhiqNicheOnboarding::CrmNotifier.notify_async(current_user, profile)

        render json: { ok: true, profile_id: profile.id }
      else
        render json: { ok: false, errors: profile.errors.full_messages }, status: 422
      end
    end
  end
end
