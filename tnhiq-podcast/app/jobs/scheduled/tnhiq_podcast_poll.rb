# frozen_string_literal: true

module ::Jobs
  class TnhiqPodcastPoll < ::Jobs::Scheduled
    every 4.hours

    def execute(_args)
      return unless SiteSetting.tnhiq_podcast_enabled
      return if SiteSetting.tnhiq_podcast_rss_url.to_s.strip.empty?

      result = ::TnhiqPodcast::RssFetcher.poll_and_ingest
      Rails.logger.info("[tnhiq-podcast] scheduled poll: #{result.inspect}")
    end
  end
end
