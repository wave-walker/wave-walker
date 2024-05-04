# frozen_string_literal: true

class AddCostDecimalsToAssetPairs < ActiveRecord::Migration[7.1]
  def change
    add_column :asset_pairs, :cost_decimals, :integer
  end
end
