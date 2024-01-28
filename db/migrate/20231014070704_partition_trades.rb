# frozen_string_literal: true

class PartitionTrades < ActiveRecord::Migration[7.1]
  def up
    drop_table :trades

    execute <<-SQL.squish
      CREATE SEQUENCE trades_id_seq
        START WITH 1
        INCREMENT BY 1
        NO MINVALUE
        NO MAXVALUE
        CACHE 1
    SQL

    create_table(:trades, primary_key: %i[asset_id id], options: 'PARTITION BY LIST (asset_id)') do |t|
      t.bigint :id, null: false # rubocop:todo Rails/DangerousColumnNames
      t.belongs_to :asset, null: false, foreign_key: true, index: false
      t.float :price, null: false
      t.float :volume, null: false

      t.timestamp :created_at, null: false
    end

    execute 'ALTER SEQUENCE trades_id_seq OWNED BY trades.id'
    execute "ALTER TABLE ONLY trades ALTER COLUMN id SET DEFAULT nextval('trades_id_seq'::regclass)"
  end

  def down
    drop_table :trades

    create_table :trades do |t|
      t.decimal :price, precision: 20, scale: 10, null: false
      t.decimal :volume, precision: 20, scale: 10, null: false

      t.timestamp :created_at, null: false
      t.references :asset, null: false, foreign_key: true
    end
  end
end
