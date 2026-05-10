# frozen_string_literal: true

module ::TnhiqPodcast
  class AdminController < ::ApplicationController
    requires_plugin "tnhiq-podcast"

    layout false
    skip_before_action :preload_json, only: [:index]
    skip_before_action :check_xhr, only: [:index]

    INDEX_TEMPLATE_PATH = File.expand_path(
      "../../views/tnhiq_podcast/admin/index.html.erb",
      __dir__,
    ).freeze

    before_action :ensure_admin

    # GET /admin/plugins/tnhiq-podcast/dashboard
    def index
      @episodes = ::TnhiqPodcast::IngestedEpisode.order(created_at: :desc).limit(50)
      @rss_url  = SiteSetting.tnhiq_podcast_rss_url
      @last_poll = ::Jobs::TnhiqPodcastPoll.last_run rescue nil
      template = File.read(INDEX_TEMPLATE_PATH)
      render inline: template, type: :erb, layout: false
    end

    # POST /admin/plugins/tnhiq-podcast/poll-now
    def poll_now
      result = ::TnhiqPodcast::RssFetcher.poll_and_ingest
      render json: result
    end

    # POST /admin/plugins/tnhiq-podcast/ingest-one
    # Body: an episode hash (guid, title, description, pub_date, audio_url, duration, episode_number, tags[])
    # Used for testing the pipeline without an actual RSS server.
    def ingest_one
      episode = {
        guid:           params[:guid].to_s,
        title:          params[:title].to_s,
        description:    params[:description].to_s,
        pub_date:       parse_date(params[:pub_date]),
        audio_url:      params[:audio_url].to_s.presence,
        audio_type:     params[:audio_type].to_s.presence,
        duration:       params[:duration].to_s.presence,
        episode_number: params[:episode_number].to_s.presence,
        tags:           Array(params[:tags]).map(&:to_s),
      }

      result = ::TnhiqPodcast::EpisodeIngester.ingest(episode)
      status = result[:ok] ? 200 : 422
      render json: result, status: status
    end

    private

    def ensure_admin
      raise ::Discourse::InvalidAccess unless current_user&.admin?
    end

    def parse_date(s)
      return nil if s.blank?
      Time.parse(s.to_s)
    rescue ArgumentError
      nil
    end
  end
end
