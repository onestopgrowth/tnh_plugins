# frozen_string_literal: true

class CreateTnhiqSponsorPlacements < ActiveRecord::Migration[7.1]
  def change
    create_table :tnhiq_sponsor_placements do |t|
      t.string  :slot, null: false
      t.string  :sponsor_name, null: false
      t.string  :sponsor_logo_url
      t.string  :sponsor_link, null: false
      t.string  :cta_text
      t.string  :target_niche
      t.bigint  :target_group_id
      t.bigint  :category_id
      t.boolean :active, null: false, default: true
      t.datetime :starts_at
      t.datetime :ends_at
      t.timestamps
    end

    add_index :tnhiq_sponsor_placements, :slot
    add_index :tnhiq_sponsor_placements, :active
    add_index :tnhiq_sponsor_placements, :target_niche
    add_index :tnhiq_sponsor_placements, :target_group_id
    add_index :tnhiq_sponsor_placements, :category_id

    # Category exclusivity: only ONE active placement per (slot, category) combination.
    add_index :tnhiq_sponsor_placements,
              %i[slot category_id],
              unique: true,
              where: "active = true AND category_id IS NOT NULL",
              name: "idx_tnhiq_sponsor_unique_active_per_category"
  end
end
