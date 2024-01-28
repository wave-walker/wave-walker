# frozen_string_literal: true

class RemoveCurserPositionFromAssetPair < ActiveRecord::Migration[7.1]
  def change
    remove_column :asset_pairs, :kraken_cursor_position, :bigint, default: 0, null: false
  end
end
