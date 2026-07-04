# frozen_string_literal: true

module ::TnhiqOnboarding
  class OnboardingController < ::ApplicationController
    requires_plugin "tnhiq-onboarding"

    layout false
    skip_before_action :preload_json, only: %i[index result]
    skip_before_action :check_xhr, only: %i[index result]

    before_action :ensure_logged_in

    VIEW_DIR = File.expand_path("../../views/tnhiq_onboarding/onboarding", __dir__).freeze

    # ── Assessment page ────────────────────────────────────────────────
    def index
      skip_this = params[:force].blank?
      return redirect_to "/founders/onboarding/result" if skip_this && ::TnhiqOnboarding::Segmenter.completed?(current_user)

      render_page("index")
    end

    # ── JSON status (used by the first-login redirect initializer) ─────
    def status
      render json: {
        completed: ::TnhiqOnboarding::Segmenter.completed?(current_user),
        path: current_user.custom_fields["tnhiq_path"],
      }
    end

    # ── Submit intake ──────────────────────────────────────────────────
    def submit
      answers = {
        stage: params[:stage].to_s,
        interests: string_array(params[:interests]),
        pain_point: params[:pain_point].to_s,
        resources: string_array(params[:resources]),
        goal_90_day: params[:goal_90_day].to_s,
        help_wanted: string_array(params[:help_wanted]),
      }

      errors = ::TnhiqOnboarding::Answers.validate(answers)
      if errors.any?
        return render json: { ok: false, errors: errors }, status: 422
      end

      path_key = ::TnhiqOnboarding::PathAssigner.call(
        stage: answers[:stage],
        interests: answers[:interests],
        pain_point: answers[:pain_point],
        help_wanted: answers[:help_wanted],
      )

      ::TnhiqOnboarding::Segmenter.apply!(current_user, answers, path_key)

      render json: { ok: true, path: path_key, redirect_url: "/founders/onboarding/result" }
    end

    # ── Result page ────────────────────────────────────────────────────
    def result
      return redirect_to "/founders/onboarding" unless ::TnhiqOnboarding::Segmenter.completed?(current_user)

      render_page("result")
    end

    private

    def render_page(name)
      # Server-rendered standalone page (no Ember shell) — matches the existing
      # tnhiq plugin convention and keeps V1 dependency-free.
      @path_key = current_user.custom_fields["tnhiq_path"]
      @path = ::TnhiqOnboarding::Paths.fetch(@path_key) if @path_key
      template = File.read(File.join(VIEW_DIR, "#{name}.html.erb"))
      render inline: template, type: :erb, layout: false
    end

    def string_array(param)
      Array(param).map(&:to_s).reject(&:blank?)
    end

    # Standalone page rendering flags (mirrors tnhiq-niche-onboarding).
    def use_crawler_layout?
      false
    end

    def ember_cli_required?
      false
    end
  end
end
