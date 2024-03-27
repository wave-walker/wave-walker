# frozen_string_literal: true

class Ohlc < ApplicationRecord
  class Range < ::Range
    attr_reader :timeframe

    def self.next_new_range(asset_pair:, timeframe:)
      timestamp = Ohlc.where(asset_pair:, timeframe:).last&.range&.last ||
                  asset_pair.trades.first.created_at

      new(timeframe, timestamp)
    end

    def initialize(timeframe, timestamp)
      @timeframe = timeframe

      @duration = ActiveSupport::Duration.parse(timeframe.to_s)
      start_at = Time.zone.at(0) + (@duration * (timestamp.to_i / @duration))
      end_at = start_at + @duration

      super(start_at, end_at, true)
    end

    def next
      self.class.new(duration.iso8601, self.end)
    end

    private

    attr_reader :duration
  end
end
