# frozen_string_literal: true

module ::TnhiqOnboarding
  # Staff-only onboarding report. Aggregates the intake custom fields.
  # (For richer/ad-hoc reporting, the bundled Data Explorer queries in the
  # README cover the same data without custom code.)
  class AdminReportController < ::Admin::AdminController
    requires_plugin "tnhiq-onboarding"

    def index
      render json: {
        total_completed: field_scope("tnhiq_onboarding_completed_at").count,
        by_stage: tally("tnhiq_stage"),
        by_pain_point: tally("tnhiq_pain_point"),
        by_path: tally("tnhiq_path"),
        by_interest: tally_json("tnhiq_interests"),
        by_help_wanted: tally_json("tnhiq_help_wanted"),
        recent_goals: field_scope("tnhiq_goal_90_day").order(id: :desc).limit(20).pluck(:value),
      }
    end

    private

    def field_scope(name)
      UserCustomField.where(name: name).where.not(value: [nil, ""])
    end

    # Count single-value fields, most common first.
    def tally(name)
      field_scope(name).group(:value).count.sort_by { |_, c| -c }.to_h
    end

    # Count values inside JSON-array fields (interests, help_wanted).
    def tally_json(name)
      counts = Hash.new(0)
      field_scope(name).pluck(:value).each do |raw|
        parsed =
          begin
            JSON.parse(raw)
          rescue StandardError
            nil
          end
        Array(parsed).each { |item| counts[item.to_s] += 1 }
      end
      counts.sort_by { |_, c| -c }.to_h
    end
  end
end
