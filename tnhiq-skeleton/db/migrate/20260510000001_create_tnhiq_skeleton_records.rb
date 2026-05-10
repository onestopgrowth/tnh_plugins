# frozen_string_literal: true

class CreateTnhiqSkeletonRecords < ActiveRecord::Migration[7.1]
  def change
    create_table :tnhiq_skeleton_records do |t|
      t.string :message, null: false
      t.timestamps
    end
  end
end
