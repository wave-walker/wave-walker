class CreateAssetPairs < ActiveRecord::Migration[7.1]
  def change
    create_table :asset_pairs do |t|
      t.string :name, null: false, index: { unique: true }
      t.boolean :sync, null: false, default: false
      t.bigint :kraken_cursor_position, default: 0, null: false

      t.timestamps
    end

    remove_foreign_key :trades, :assets
    rename_column :trades, :asset_id, :asset_pair_id
    add_foreign_key :trades, :asset_pairs

    drop_table :assets do |t|
      t.string :name, null: false, index: { unique: true }
      t.bigint :kraken_cursor_position, default: 0, null: false

      t.timestamps
    end
  end
end
