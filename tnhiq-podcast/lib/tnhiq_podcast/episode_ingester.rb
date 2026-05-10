# frozen_string_literal: true

module ::TnhiqPodcast
  # Idempotent ingester: take a normalized episode hash, create a Discourse Topic
  # in the right category, pin it, and record the GUID to prevent duplicates.
  module EpisodeIngester
    module_function

    def ingest(episode)
      guid = episode[:guid].to_s.strip
      return { ok: false, error: "missing_guid" } if guid.empty?

      title = episode[:title].to_s.strip
      return { ok: false, error: "missing_title" } if title.empty?

      existing = ::TnhiqPodcast::IngestedEpisode.find_by(guid: guid)
      return { ok: true, created: false, episode_id: existing.id, topic_id: existing.topic_id } if existing

      category = ::TnhiqPodcast::CategoryRouter.category_for(episode[:tags])
      return { ok: false, error: "no_category_resolvable" } unless category

      tags = derive_tags(episode, category)
      raw  = build_topic_body(episode)

      pc =
        ::PostCreator.new(
          ::Discourse.system_user,
          title:        title,
          raw:          raw,
          category:     category.id,
          tags:         tags,
          archetype:    ::Archetype.default,
          skip_validations: true,
        )

      post = pc.create

      if post.nil? || pc.errors.any?
        return { ok: false, error: "post_create_failed", details: pc.errors.full_messages }
      end

      pin_topic(post.topic)

      ::TnhiqPodcast::IngestedEpisode.create!(
        guid:           guid,
        title:          title,
        topic_id:       post.topic_id,
        category_id:    category.id,
        audio_url:      episode[:audio_url],
        episode_number: episode[:episode_number],
        published_at:   episode[:pub_date],
      )

      { ok: true, created: true, topic_id: post.topic_id, category_id: category.id }
    rescue StandardError => e
      Rails.logger.warn("[tnhiq-podcast] ingest failed for #{guid}: #{e.class} #{e.message}")
      { ok: false, error: "exception", details: e.message }
    end

    def derive_tags(episode, category)
      base = ["podcast"]
      base.concat(Array(episode[:tags]).map { |t| t.to_s.downcase.tr(" ", "-").gsub(/[^a-z0-9_\-]/, "") }.reject(&:empty?))
      # If we routed to "announcements" as a fallback, mark as podcast for filtering.
      base << "podcast-default" if category.slug == "announcements"
      base.uniq.first(8)
    end

    def build_topic_body(episode)
      audio_block = episode[:audio_url].present? ? episode[:audio_url] : "_(audio link not provided)_"
      tags_display = Array(episode[:tags]).join(", ").presence || "_(none)_"

      <<~MARKDOWN
        **Episode:** #{episode[:episode_number].presence || "—"}
        **Guest:** #{guess_guest(episode).presence || "—"}
        **Runtime:** #{episode[:duration].presence || "—"}

        #{episode[:description].to_s.strip}

        ---
        **Listen:** #{audio_block}

        **Key Niches:** #{tags_display}

        **Discussion:** Drop your takeaways below.
      MARKDOWN
    end

    # Best-effort guest extraction: look for "with <Name>" or "feat. <Name>" in title.
    def guess_guest(episode)
      title = episode[:title].to_s
      m = title.match(/\bwith\s+([A-Z][\w'.\- ]+?)(?:\s+[-—|]|$)/) ||
          title.match(/\bfeat\.?\s+([A-Z][\w'.\- ]+)/i)
      m && m[1].strip
    end

    def pin_topic(topic)
      pin_days = SiteSetting.tnhiq_podcast_pin_days.to_i
      return if pin_days <= 0
      topic.update_columns(
        pinned_at:    Time.current,
        pinned_until: pin_days.days.from_now,
      )
    end
  end
end
