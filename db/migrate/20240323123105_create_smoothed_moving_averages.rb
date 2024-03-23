# frozen_string_literal: true

class CreateSmoothedMovingAverages < ActiveRecord::Migration[7.1]
  def change
    create_table :smoothed_moving_averages, primary_key: %i[ohlc_id interval] do |t|
      t.belongs_to :ohlc, null: false, foreign_key: true, index: false
      t.integer :interval, null: false
      t.float :value, null: false

      t.timestamp :created_at, null: false
    end
  end
end
