# frozen_string_literal: true

class ChangeAssetPairImporting < ActiveRecord::Migration[7.1]
  def up
    change_table :asset_pairs, bulk: true do
      remove_column :asset_pairs, :trades_count
      remove_column :asset_pairs, :import_status, :import_state, default: 'pending', null: false
      drop_enum :import_state, %w[pending waiting importing imported]

      add_column :asset_pairs, :importing, :boolean, default: false, null: false
    end
  end

  def down
    change_table :asset_pairs, bulk: true do
      remove_column :asset_pairs, :importing
      add_column :asset_pairs, :trades_count, :integer, null: false, default: 0
      create_enum :import_state, %w[pending waiting importing imported]
      add_column :asset_pairs, :import_status, :import_state, default: 'pending', null: false
      add_index :asset_pairs, :import_status, where: 'import_status = \'importing\'', unique: true
    end
  end
end
