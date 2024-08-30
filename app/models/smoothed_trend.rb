# frozen_string_literal: true

class SmoothedTrend < ApplicationRecord
  include DurationConcern
  include RangeConcern

  belongs_to :asset_pair
  belongs_to :ohlc, foreign_key: %i[asset_pair_id iso8601_duration range_position],
                    inverse_of: :smoothed_trend

  enum :trend, { bearish: 'bearish', neutral: 'neutral', bullish: 'bullish' }

  scope :recent_daily_flips, -> { by_duration_before(1.day, 1.week.ago).where(flip: true) }
  scope :by_duration_before, lambda { |duration, time|
    by_duration(duration).where(range_position: OhlcRangeValue.at(duration:, time:).position...)
  }
end
