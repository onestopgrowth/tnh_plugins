# frozen_string_literal: true

module ::TnhiqOpportunities
  module TierGate
    # Each tier subsumes the ones below it.
    TIER_ORDER = %w[free core premium founder].freeze

    GROUP_TO_TIER = {
      "tnh_free"     => "free",
      "tnh_core"     => "core",
      "tnh_premium"  => "premium",
      "tnh_founder"  => "founder",
      "tnh_staff"    => "founder", # staff sees everything
    }.freeze

    module_function

    def user_tier(user)
      return nil unless user

      group_names = user.groups.pluck(:name)
      best = nil
      group_names.each do |g|
        tier = GROUP_TO_TIER[g]
        next unless tier
        if best.nil? || TIER_ORDER.index(tier) > TIER_ORDER.index(best)
          best = tier
        end
      end
      best || "free"
    end

    def accessible?(user, opportunity)
      return false unless user
      tier = user_tier(user)
      TIER_ORDER.index(tier) >= TIER_ORDER.index(opportunity.tier_required)
    end
  end
end
