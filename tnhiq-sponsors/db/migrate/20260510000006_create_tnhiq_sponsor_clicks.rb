# frozen_string_literal: true

class CreateTnhiqSponsorClicks < ActiveRecord::Migration[7.1]
  def change
    create_table :tnhiq_sponsor_clicks do |t|
      t.references :placement,
                   null: false,
                   foreign_key: { to_table: :tnhiq_sponsor_placements, on_delete: :cascade }
      t.bigint  :user_id
      t.datetime :clicked_at, null: false
      t.string  :page_url, limit: 1024
      t.string  :ip_address, limit: 64
      t.string  :user_agent, limit: 512
    end

    add_index :tnhiq_sponsor_clicks, :user_id
    add_index :tnhiq_sponsor_clicks, :clicked_at
  end
end
