# frozen_string_literal: true

module ::TnhiqNicheOnboarding
  class CategorySubscriber
    NICHE_TO_CATEGORY_SLUGS = {
      "owner_operator"   => %w[owner-operators],
      "fleet_owner"      => %w[owner-operators business-growth],
      "freight_broker"   => %w[freight-brokerage],
      "dispatcher"       => %w[freight-brokerage],
      "last_mile_dsp"    => %w[last-mile],
      "box_truck"        => %w[business-growth],
      "hotshot"          => %w[business-growth],
      "warehousing_3pl"  => %w[business-growth],
      "getting_started"  => %w[getting-started],
    }.freeze

    TRACKING_LEVEL = ::CategoryUser.notification_levels[:tracking]

    def initialize(user, niche)
      @user = user
      @niche = niche
    end

    def subscribe!
      slugs = NICHE_TO_CATEGORY_SLUGS[@niche] || []
      return if slugs.empty?

      guardian = ::Guardian.new(@user)

      ::Category.where(slug: slugs).find_each do |category|
        next unless guardian.can_see_category?(category)
        ::CategoryUser.set_notification_level_for_category(@user, TRACKING_LEVEL, category.id)
      end
    end
  end
end
