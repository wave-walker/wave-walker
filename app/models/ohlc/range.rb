# frozen_string_literal: true

class Ohlc < ApplicationRecord
  class Range < ::Range
    attr_reader :timeframe

    def initialize(timeframe, timestamp)
      @timeframe = timeframe
      @duration = ActiveSupport::Duration.parse(timeframe)
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
