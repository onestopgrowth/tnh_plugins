# frozen_string_literal: true

module ::TnhiqOnboarding
  # Path metadata: the group setting that resolves the Discourse group, the
  # recommended room (category slug + name), the first action, and the result-page
  # explanation. Path keys match the settings.yml suffixes.
  module Paths
    PATHS = {
      "beginner_explorer" => {
        group_setting: :tnhiq_onboarding_group_beginner_explorer,
        name: "Beginner Explorer",
        room_slug: "business-model-breakdown",
        room_name: "Business Model Breakdown",
        first_action: "Post your introduction and tell the community which business models you are considering.",
        body: "You are still choosing the right transportation lane. Your focus should not be buying equipment or jumping into a business model too quickly. Your first move is to understand what each business really costs, how it makes money, and what it requires.",
      },
      "driver_owner_operator" => {
        group_setting: :tnhiq_onboarding_group_driver_owner_operator,
        name: "Driver / Owner-Operator",
        room_slug: "numbers-rates-and-costs",
        room_name: "Numbers, Rates & Costs",
        first_action: "Post your current stage and your biggest cost, freight, equipment, or compliance question.",
        body: "You are either working toward ownership or already operating. Your focus should be understanding your numbers, controlling costs, finding better freight, and avoiding decisions that create unnecessary pressure.",
      },
      "small_fleet_builder" => {
        group_setting: :tnhiq_onboarding_group_small_fleet_builder,
        name: "Small Fleet Builder",
        room_slug: "operations-systems-and-hiring",
        room_name: "Operations, Systems & Hiring",
        first_action: "Post your fleet size, your biggest bottleneck, and what you are trying to fix in the next 90 days.",
        body: "You are past the idea stage. Your focus is systems, drivers, safety, cash flow, dispatch, maintenance, and building an operation that does not depend on chaos every day.",
      },
      "non_asset_builder" => {
        group_setting: :tnhiq_onboarding_group_non_asset_builder,
        name: "Non-Asset Builder",
        room_slug: "customers-contracts-and-freight",
        room_name: "Customers, Contracts & Freight",
        first_action: "Post what service you want to build and who you believe your customer is.",
        body: "You may be building through brokerage, dispatching, compliance, admin support, recruiting, or other service-based transportation businesses. Your focus is choosing a clear customer, learning the workflow, and building trust.",
      },
      "specialized_contract_builder" => {
        group_setting: :tnhiq_onboarding_group_specialized_contract_builder,
        name: "Specialized / Contract Builder",
        room_slug: "business-model-breakdown",
        room_name: "Business Model Breakdown",
        first_action: "Post the niche you are exploring and what you need to understand before making a move.",
        body: "You are interested in a more specific lane such as dump trucks, hot shot, government contracts, drayage, towing, truck parking, routes, or niche transportation opportunities. Your focus is understanding the model before committing money or equipment.",
      },
      "vendor_partner" => {
        group_setting: :tnhiq_onboarding_group_vendor_partner,
        name: "Vendor / Partner",
        room_slug: "ask-the-community",
        room_name: "Ask the Community",
        first_action: "Post who you serve, what problem you solve, and how you can be useful to the community without pitching.",
        body: "You serve the transportation industry. This community is not for cold pitching. It is for becoming useful, understanding what operators need, and building trust through education and support.",
      },
    }.freeze

    module_function

    def all
      PATHS
    end

    def fetch(path_key)
      PATHS[path_key] || PATHS["beginner_explorer"]
    end

    def keys
      PATHS.keys
    end

    # Resolve the configured Discourse group name for a path.
    def group_name(path_key)
      meta = fetch(path_key)
      SiteSetting.get(meta[:group_setting].to_s)
    end
  end
end
