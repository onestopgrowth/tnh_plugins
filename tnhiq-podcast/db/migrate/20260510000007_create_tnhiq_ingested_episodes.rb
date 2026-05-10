# frozen_string_literal: true

class CreateTnhiqIngestedEpisodes < ActiveRecord::Migration[7.1]
  def change
    create_table :tnhiq_ingested_episodes do |t|
      t.string  :guid, null: false
      t.string  :title, null: false
      t.bigint  :topic_id
      t.bigint  :category_id
      t.string  :audio_url
      t.string  :episode_number
      t.datetime :published_at
      t.timestamps
    end

    add_index :tnhiq_ingested_episodes, :guid, unique: true
    add_index :tnhiq_ingested_episodes, :topic_id
    add_index :tnhiq_ingested_episodes, :published_at
  end
end
