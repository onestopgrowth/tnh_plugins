# frozen_string_literal: true

require "net/http"
require "uri"
require "nokogiri"

module ::TnhiqPodcast
  # Fetches the configured RSS feed and yields normalized episode hashes.
  module RssFetcher
    module_function

    def poll_and_ingest
      url = SiteSetting.tnhiq_podcast_rss_url.to_s.strip
      return { ok: false, error: "rss_url_not_configured" } if url.empty?

      xml = fetch(url)
      return { ok: false, error: "fetch_failed" } unless xml

      episodes = parse(xml)
      max = SiteSetting.tnhiq_podcast_max_per_poll.to_i
      max = 5 if max <= 0

      created = 0
      episodes.first(max).each do |ep|
        result = ::TnhiqPodcast::EpisodeIngester.ingest(ep)
        created += 1 if result[:ok] && result[:created]
      end

      { ok: true, fetched: episodes.size, created: created }
    end

    def fetch(url)
      uri = URI.parse(url)
      response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https", open_timeout: 5, read_timeout: 15) do |http|
        http.get(uri.request_uri, "User-Agent" => "TNHIQ-Discourse/0.1")
      end
      return nil unless response.is_a?(Net::HTTPSuccess)
      response.body
    rescue StandardError => e
      Rails.logger.warn("[tnhiq-podcast] RSS fetch failed: #{e.class} #{e.message}")
      nil
    end

    # Returns an array of normalized episode hashes:
    # { guid, title, description, pub_date, audio_url, audio_type, duration, episode_number, tags }
    def parse(xml)
      doc = ::Nokogiri::XML(xml)
      doc.remove_namespaces!

      doc.css("rss > channel > item").map do |item|
        enclosure = item.at_css("enclosure")
        {
          guid:           item.at_css("guid")&.text&.strip,
          title:          item.at_css("title")&.text&.strip,
          description:    item.at_css("description")&.text&.strip,
          pub_date:       parse_date(item.at_css("pubDate")&.text),
          audio_url:      enclosure&.[]("url"),
          audio_type:     enclosure&.[]("type"),
          duration:       item.at_css("duration")&.text&.strip,
          episode_number: item.at_css("episode")&.text&.strip,
          tags:           item.css("category").map { |c| c.text.strip }.reject(&:empty?),
        }
      end
    end

    def parse_date(s)
      return nil if s.blank?
      Time.parse(s)
    rescue ArgumentError
      nil
    end
  end
end
