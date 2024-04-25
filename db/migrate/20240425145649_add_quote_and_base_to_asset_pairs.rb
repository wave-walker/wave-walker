# frozen_string_literal: true

class AddQuoteAndBaseToAssetPairs < ActiveRecord::Migration[7.1]
  def change
    change_table :asset_pairs, bulk: true do |t|
      t.string :quote
      t.string :base
    end
  end
end
