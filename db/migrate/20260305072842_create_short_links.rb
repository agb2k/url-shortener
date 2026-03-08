class CreateShortLinks < ActiveRecord::Migration[8.1]
  def change
    # Only run on primary (Postgres); analytics uses separate migrations in db/clickhouse_migrate
    return unless connection.adapter_name.match?(/PostgreSQL/i)

    create_table :short_links do |t|
      t.text :original_url, null: false
      t.string :short_code, null: false
      t.string :title

      t.timestamps
    end

    add_index :short_links, :short_code, unique: true
  end
end
