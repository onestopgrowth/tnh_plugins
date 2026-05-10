# frozen_string_literal: true

module ::TnhiqNicheOnboarding
  class CrmNotifier
    PATH = "/discourse/member-profile"

    def self.notify_async(user, profile)
      ::Jobs.enqueue(:tnhiq_niche_onboarding_crm_notify,
                     user_id: user.id,
                     profile_id: profile.id)
    end

    def self.notify_now(user, profile)
      base = SiteSetting.tnhiq_niche_onboarding_crm_url.to_s.strip
      return :skipped if base.empty?

      timeout = SiteSetting.tnhiq_niche_onboarding_crm_timeout_seconds.to_i
      timeout = 10 if timeout <= 0

      payload = {
        discourse_user_id: user.id,
        email:             user.email,
        niche:             profile.niche,
        equipment:         profile.equipment,
        stage:             profile.stage,
      }.to_json

      response = Excon.post(
        "#{base.chomp("/")}#{PATH}",
        body:            payload,
        headers:         { "Content-Type" => "application/json" },
        connect_timeout: timeout,
        read_timeout:    timeout,
        expects:         [200, 201, 202, 204],
      )

      profile.update_column(:crm_synced_at, Time.current)
      response
    rescue Excon::Error => e
      Rails.logger.warn("[tnhiq-niche-onboarding] CRM sync failed: #{e.class} #{e.message}")
      nil
    end
  end

  module ::Jobs
    class TnhiqNicheOnboardingCrmNotify < ::Jobs::Base
      def execute(args)
        user    = ::User.find_by(id: args[:user_id])
        profile = ::TnhiqNicheOnboarding::Profile.find_by(id: args[:profile_id])
        return unless user && profile
        ::TnhiqNicheOnboarding::CrmNotifier.notify_now(user, profile)
      end
    end
  end
end
