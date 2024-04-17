# frozen_string_literal: true

class SmoothedTrend < ApplicationRecord
  include DurationConcern
  include RangeConcern

  belongs_to :asset_pair

  scope :recent_daily_flips, -> { by_duration_before(1.day, 1.week.ago).where(flip: true) }
  scope :by_duration_before, lambda { |duration, time|
    by_duration(duration).where(range_position: OhlcRangeValue.at(duration:, time:).position...)
  }
end
