# frozen_string_literal: true

class AddFlipToSmoothedTrends < ActiveRecord::Migration[7.1]
  def change
    add_column :smoothed_trends, :flip, :boolean, null: false, default: false # rubocop:disable Rails/BulkChangeTable
    change_column_default :smoothed_trends, :flip, from: false, to: nil
  end
end
