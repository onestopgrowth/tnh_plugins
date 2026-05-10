# frozen_string_literal: true

class CreateTnhiqOpportunities < ActiveRecord::Migration[7.1]
  def change
    create_table :tnhiq_opportunities do |t|
      t.string  :title, null: false
      t.text    :description
      t.string  :equipment_type
      t.string  :origin_state, limit: 4
      t.string  :destination_state, limit: 4
      t.string  :commodity
      t.string  :source_type, null: false, default: "internal"
      t.string  :source_label
      t.references :posted_by_user, foreign_key: { to_table: :users }, null: true
      t.datetime :expires_at
      t.string  :tier_required, null: false, default: "free"
      t.boolean :requires_verified, null: false, default: false
      t.string  :status, null: false, default: "active"
      t.string  :external_reference_id
      t.timestamps
    end

    add_index :tnhiq_opportunities, :status
    add_index :tnhiq_opportunities, :tier_required
    add_index :tnhiq_opportunities, :equipment_type
    add_index :tnhiq_opportunities, :origin_state
    add_index :tnhiq_opportunities, :destination_state
    add_index :tnhiq_opportunities, :expires_at
    add_index :tnhiq_opportunities, :external_reference_id, unique: true, where: "external_reference_id IS NOT NULL"
  end
end
