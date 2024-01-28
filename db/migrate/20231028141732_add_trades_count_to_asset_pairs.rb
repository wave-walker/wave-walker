# frozen_string_literal: true

class AddTradesCountToAssetPairs < ActiveRecord::Migration[7.1]
  def change
    add_column :asset_pairs, :trades_count, :integer, default: 0, null: false
  end
end
