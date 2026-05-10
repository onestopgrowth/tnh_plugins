# frozen_string_literal: true

module ::TnhiqPodcast
  # Maps an RSS item's tag set onto the right Discourse category.
  # Falls back to the configured default category when nothing matches.
  module CategoryRouter
    # Each entry: regex against any one tag → category slug.
    TAG_RULES = [
      [/owner[-_]?operator|operator|trucker/i, "owner-operators"],
      [/freight|broker|brokerage|dispatch/i,   "freight-brokerage"],
      [/last[-_]?mile|amazon|dsp|delivery/i,   "last-mile"],
      [/business|growth|scaling|cash[-_]?flow|finance/i, "business-growth"],
    ].freeze

    module_function

    def category_for(tags)
      tags = Array(tags).compact.map(&:to_s)
      slug = TAG_RULES.find { |re, _| tags.any? { |t| t =~ re } }&.last
      slug ||= SiteSetting.tnhiq_podcast_default_category.to_s.presence || "announcements"
      ::Category.find_by(slug: slug) || ::Category.find_by(slug: "announcements")
    end
  end
end
