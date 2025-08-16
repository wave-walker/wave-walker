# frozen_string_literal: true

class NoNullForAssetPairParameter < ActiveRecord::Migration[7.1]
  def change
    change_column_null :asset_pairs, :base, false
    change_column_null :asset_pairs, :quote, false
    change_column_null :asset_pairs, :cost_decimals, false
  end
end
