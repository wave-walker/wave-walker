# frozen_string_literal: true

class AddImportStateToAssetPair < ActiveRecord::Migration[7.1]
  def change
    create_enum :import_state, %w[pending waiting importing imported]

    add_column :asset_pairs, :import_state, :import_state, default: 'pending', null: false
    add_index :asset_pairs, :import_state, where: 'import_state = \'importing\'', unique: true
    remove_column :asset_pairs, :importing, :boolean, default: false, null: false
  end
end
