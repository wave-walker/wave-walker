# frozen_string_literal: true

class AddNameOnExchangeToAssetPairs < ActiveRecord::Migration[7.1]
  def change
    add_column :asset_pairs, :name_on_exchange, :string, null: false # rubocop:disable Rails/NotNullColumn
    add_index :asset_pairs, :name_on_exchange, unique: true
  end
end
