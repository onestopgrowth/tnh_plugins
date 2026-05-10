# frozen_string_literal: true

module ::TnhiqPodcast
  class IngestedEpisode < ::ActiveRecord::Base
    self.table_name = "tnhiq_ingested_episodes"

    validates :guid, presence: true, uniqueness: true
    validates :title, presence: true
  end
end
