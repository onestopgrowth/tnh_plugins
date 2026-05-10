# frozen_string_literal: true

class CreateTnhiqNicheProfiles < ActiveRecord::Migration[7.1]
  def change
    create_table :tnhiq_niche_profiles do |t|
      t.references :user, null: false, index: { unique: true }
      t.string :niche, null: false
      t.string :equipment, array: true, default: [], null: false
      t.string :stage, null: false
      t.datetime :completed_at, null: false
      t.datetime :crm_synced_at
      t.timestamps
    end

    add_index :tnhiq_niche_profiles, :niche
  end
end
