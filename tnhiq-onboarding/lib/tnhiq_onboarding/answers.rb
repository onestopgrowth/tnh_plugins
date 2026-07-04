# frozen_string_literal: true

module ::TnhiqOnboarding
  # Allowlists for the 6-question intake + server-side validation.
  module Answers
    STAGES = %w[
      stage_exploring stage_driver_to_owner stage_owner_operator stage_small_fleet
      stage_dispatch_broker_backoffice stage_existing_business_expansion stage_vendor stage_not_sure
    ].freeze

    INTERESTS = %w[
      interest_box_truck_final_mile interest_dump_truck_construction interest_hot_shot
      interest_freight_brokerage interest_dispatching interest_government_contracting
      interest_ports_drayage_intermodal interest_towing interest_truck_parking_yards
      interest_route_business interest_small_fleet interest_compliance_backoffice_safety interest_not_sure
    ].freeze

    PAIN_POINTS = %w[
      pain_choose_business pain_understand_numbers pain_customers_contracts pain_financing_equipment
      pain_insurance_compliance pain_better_freight pain_operations_systems pain_hiring_team
      pain_scaling pain_overwhelmed_direction
    ].freeze

    CAPITAL = %w[
      capital_under_1000 capital_1000_5000 capital_5000_10000 capital_10000_25000
      capital_25000_50000 capital_50000_plus
    ].freeze

    RESOURCE_MODIFIERS = %w[
      resource_has_equipment resource_has_credit_financing resource_has_relationships
      resource_time_limited_money resource_money_limited_time
    ].freeze

    RESOURCES = (CAPITAL + RESOURCE_MODIFIERS).freeze

    HELP = %w[
      help_peer_support help_case_studies help_templates_worksheets help_live_calls
      help_coaching_accountability help_vendor_recommendations help_business_opportunities
      help_choose_lane help_fix_current_business
    ].freeze

    module_function

    # Returns an array of error strings ([] means valid).
    def validate(a)
      errors = []

      errors << "Please choose your current stage." unless STAGES.include?(a[:stage])

      errors.concat(validate_multi(a[:interests], INTERESTS, "interest"))
      if Array(a[:interests]).include?("interest_not_sure") && Array(a[:interests]).size > 2
        errors << "When 'Not sure' is selected, choose at most one other interest."
      end

      errors << "Please choose your biggest challenge." unless PAIN_POINTS.include?(a[:pain_point])

      errors.concat(validate_multi(a[:resources], RESOURCES, "resource"))
      if Array(a[:resources]).count { |r| CAPITAL.include?(r) } > 1
        errors << "Select only one dollar range."
      end

      goal = a[:goal_90_day].to_s.strip
      errors << "Your 90-day goal must be at least 20 characters." if goal.length < 20
      errors << "Your 90-day goal must be under 750 characters." if goal.length > 750

      errors.concat(validate_multi(a[:help_wanted], HELP, "help"))

      errors
    end

    def validate_multi(values, allowed, label)
      values = Array(values)
      errs = []
      errs << "Please choose at least one #{label}." if values.empty?
      errs << "Choose at most 3 #{label} options." if values.size > 3
      errs << "Duplicate #{label} selection." if values.uniq.size != values.size
      errs << "Invalid #{label} selection." unless values.all? { |v| allowed.include?(v) }
      errs
    end
  end
end
