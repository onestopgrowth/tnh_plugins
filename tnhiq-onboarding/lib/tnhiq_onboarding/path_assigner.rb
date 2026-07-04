# frozen_string_literal: true

module ::TnhiqOnboarding
  # Deterministic starting-path routing. No scoring engine — ordered rules only.
  #
  # Priority (highest first): vendor -> small fleet -> non-asset ->
  # driver/owner-operator -> specialized -> beginner. Exception: any "beginner"
  # signal routes to Beginner Explorer UNLESS the member is clearly a vendor or
  # small fleet. (Mirrors the backend onboarding.constants.ts, which is unit-tested.)
  module PathAssigner
    SPECIALIZED_INTERESTS = %w[
      interest_dump_truck_construction
      interest_hot_shot
      interest_government_contracting
      interest_ports_drayage_intermodal
      interest_towing
      interest_truck_parking_yards
      interest_route_business
    ].freeze

    module_function

    def call(stage:, interests:, pain_point:, help_wanted:)
      interests = Array(interests)
      help = Array(help_wanted)

      is_vendor = stage == "stage_vendor"

      is_small_fleet =
        stage == "stage_small_fleet" ||
        pain_point == "pain_hiring_team" ||
        pain_point == "pain_scaling" ||
        interests.include?("interest_small_fleet")

      is_non_asset =
        stage == "stage_dispatch_broker_backoffice" ||
        interests.include?("interest_freight_brokerage") ||
        interests.include?("interest_dispatching") ||
        interests.include?("interest_compliance_backoffice_safety")

      is_driver_owner_operator =
        stage == "stage_driver_to_owner" || stage == "stage_owner_operator"

      is_specialized = interests.any? { |i| SPECIALIZED_INTERESTS.include?(i) }

      is_beginner =
        stage == "stage_exploring" ||
        stage == "stage_not_sure" ||
        pain_point == "pain_choose_business" ||
        help.include?("help_choose_lane")

      # Beginner exception: wins over lower-priority paths, but a clear vendor or
      # small-fleet signal still takes precedence.
      return "beginner_explorer" if is_beginner && !is_vendor && !is_small_fleet

      return "vendor_partner" if is_vendor
      return "small_fleet_builder" if is_small_fleet
      return "non_asset_builder" if is_non_asset
      return "driver_owner_operator" if is_driver_owner_operator
      return "specialized_contract_builder" if is_specialized

      "beginner_explorer"
    end
  end
end
