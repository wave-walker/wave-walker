# frozen_string_literal: true

class CreateSmoothedTrends < ActiveRecord::Migration[7.1]
  def change
    create_enum :trend, %i[bearish neutral bullish]

    create_table :smoothed_trends, primary_key: [:ohlc_id] do |t|
      t.belongs_to :ohlc, null: false, foreign_key: true, index: false
      t.float :fast_smma, null: false
      t.float :slow_smma, null: false
      t.enum :trend, enum_type: :trend, null: false

      t.timestamp :created_at, null: false
    end
  end
end
