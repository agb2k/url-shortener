# frozen_string_literal: true

class CreateVisits < ActiveRecord::Migration[8.1]
  def change
    create_table :visits, id: false, options: "MergeTree() ORDER BY (short_link_id, created_at)" do |t|
      t.integer :short_link_id, limit: 8, null: false
      t.datetime :created_at, null: false
      t.string :ip_address
      t.string :country
      t.string :user_agent
    end
  end
end
