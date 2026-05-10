# frozen_string_literal: true

module ::TnhiqNicheOnboarding
  class Profile < ::ActiveRecord::Base
    self.table_name = "tnhiq_niche_profiles"

    NICHES = %w[
      owner_operator
      fleet_owner
      freight_broker
      dispatcher
      last_mile_dsp
      box_truck
      hotshot
      warehousing_3pl
      getting_started
    ].freeze

    EQUIPMENT = %w[
      dry_van
      reefer
      flatbed
      step_deck
      rgn
      box_truck
      cargo_van
      sprinter
      hotshot_trailer
      other
    ].freeze

    STAGES = %w[
      pre_launch
      year_one
      growing
      scaling
      established
    ].freeze

    belongs_to :user, class_name: "::User"

    validates :user_id, presence: true, uniqueness: true
    validates :niche, inclusion: { in: NICHES }
    validates :stage, inclusion: { in: STAGES }
    validate :equipment_values_valid

    private

    def equipment_values_valid
      return if equipment.blank?
      invalid = Array(equipment) - EQUIPMENT
      return if invalid.empty?
      errors.add(:equipment, "contains invalid values: #{invalid.join(", ")}")
    end
  end
end
