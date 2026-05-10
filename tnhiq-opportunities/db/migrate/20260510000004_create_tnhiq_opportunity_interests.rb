# frozen_string_literal: true

class CreateTnhiqOpportunityInterests < ActiveRecord::Migration[7.1]
  def change
    create_table :tnhiq_opportunity_interests do |t|
      t.references :opportunity,
                   null: false,
                   foreign_key: { to_table: :tnhiq_opportunities, on_delete: :cascade }
      t.references :user, null: false, foreign_key: true
      t.text :notes
      t.timestamps
    end

    add_index :tnhiq_opportunity_interests,
              %i[opportunity_id user_id],
              unique: true,
              name: "idx_tnhiq_opp_interests_unique"
  end
end
