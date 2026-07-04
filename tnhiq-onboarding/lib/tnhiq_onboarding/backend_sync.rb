# frozen_string_literal: true

require "net/http"
require "openssl"

module ::TnhiqOnboarding
  # Sends completed intake data to the backend Member Intelligence Database.
  # HMAC-signed (shared secret) so the backend can trust it. Best-effort +
  # records sync status on the user; the backend upsert is idempotent.
  module BackendSync
    module_function

    def enqueue(user_id)
      Jobs.enqueue(:tnhiq_onboarding_sync, user_id: user_id)
    end

    def sync_now(user)
      url = SiteSetting.tnhiq_onboarding_backend_url.to_s.strip
      secret = SiteSetting.tnhiq_onboarding_backend_secret.to_s
      if url.blank? || secret.blank?
        Rails.logger.warn("[tnhiq-onboarding] backend sync skipped — url/secret not set")
        return
      end

      body = build_payload(user).to_json
      sig = "sha256=" + OpenSSL::HMAC.hexdigest("SHA256", secret, body)

      uri = URI("#{url.chomp('/')}/discourse/member-profile")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"
      http.open_timeout = 10
      http.read_timeout = 10

      req = Net::HTTP::Post.new(uri.request_uri)
      req["Content-Type"] = "application/json"
      req["X-TNH-Signature"] = sig
      req.body = body

      res = http.request(req)
      if res.code.to_i.between?(200, 299)
        set_status(user, synced_at: Time.current.iso8601, error: nil)
      else
        set_status(user, error: "HTTP #{res.code}")
      end
    rescue StandardError => e
      set_status(user, error: "#{e.class}: #{e.message}")
    end

    def build_payload(user)
      cf = user.custom_fields
      {
        discourse_user_id: user.id,
        email: user.email,
        name: user.name,
        username: user.username,
        stage: cf["tnhiq_stage"],
        interests: cf["tnhiq_interests"],
        pain_point: cf["tnhiq_pain_point"],
        resources: cf["tnhiq_resources"],
        goal_90_day: cf["tnhiq_goal_90_day"],
        help_wanted: cf["tnhiq_help_wanted"],
        path: cf["tnhiq_path"],
        captured_from: "onboarding",
      }
    end

    def set_status(user, synced_at: nil, error: nil)
      Rails.logger.warn("[tnhiq-onboarding] backend sync error for user #{user.id}: #{error}") if error
      user.custom_fields["tnhiq_synced_at"] = synced_at if synced_at
      user.custom_fields["tnhiq_sync_error"] = error
      user.save_custom_fields(true)
    end
  end
end

module ::Jobs
  class TnhiqOnboardingSync < ::Jobs::Base
    def execute(args)
      user = User.find_by(id: args[:user_id])
      return if user.nil?
      ::TnhiqOnboarding::BackendSync.sync_now(user)
    end
  end
end
