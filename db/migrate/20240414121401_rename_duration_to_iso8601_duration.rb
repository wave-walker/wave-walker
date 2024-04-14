# frozen_string_literal: true

class RenameDurationToIso8601Duration < ActiveRecord::Migration[7.1]
  def change
    rename_enum :timeframe, to: :iso8601_duration
    rename_column :ohlcs, :duration, :iso8601_duration
    rename_column :smoothed_moving_averages, :duration, :iso8601_duration
    rename_column :smoothed_trends, :duration, :iso8601_duration
  end
end
