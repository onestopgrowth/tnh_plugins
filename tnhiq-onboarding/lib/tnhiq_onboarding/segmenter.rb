# frozen_string_literal: true

module ::TnhiqOnboarding
  # Persists intake answers on the user as custom fields and adds the member to
  # their assigned path group. Segmentation for TNH lives entirely on the user
  # profile (custom fields) + group membership.
  module Segmenter
    module_function

    def apply!(user, answers, path_key)
      user.custom_fields["tnhiq_stage"] = answers[:stage]
      user.custom_fields["tnhiq_interests"] = Array(answers[:interests])
      user.custom_fields["tnhiq_pain_point"] = answers[:pain_point]
      user.custom_fields["tnhiq_resources"] = Array(answers[:resources])
      user.custom_fields["tnhiq_goal_90_day"] = answers[:goal_90_day].to_s
      user.custom_fields["tnhiq_help_wanted"] = Array(answers[:help_wanted])
      user.custom_fields["tnhiq_path"] = path_key
      user.custom_fields["tnhiq_onboarding_completed_at"] = Time.current.iso8601
      user.save_custom_fields(true)

      add_to_path_group(user, path_key) if SiteSetting.tnhiq_onboarding_assign_path_groups
    end

    def completed?(user)
      user.custom_fields["tnhiq_onboarding_completed_at"].present?
    end

    def add_to_path_group(user, path_key)
      group_name = ::TnhiqOnboarding::Paths.group_name(path_key)
      return if group_name.blank?

      group = Group.find_by(name: group_name)
      if group.nil?
        Rails.logger.warn("[tnhiq-onboarding] path group '#{group_name}' not found — skipping")
        return
      end

      group.add(user) unless GroupUser.exists?(group_id: group.id, user_id: user.id)
    end
  end
end
