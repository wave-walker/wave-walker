# frozen_string_literal: true

class SmoothedMovingAverage < ApplicationRecord
  include DurationConcern

  belongs_to :asset_pair

  def self.latest_range_position(asset_pair:, duration:)
    by_duration(duration).where(asset_pair:).maximum(:range_position)
  end

  def self.create_initial_sma(asset_pair:, duration:, interval:)
    ohlcs = Ohlc.where(asset_pair:)
                .by_duration(duration)
                .order(:range_position)
                .limit(interval)

    return if ohlcs.count != interval

    range_position = ohlcs.last.range_position
    value = (ohlcs.sum(&:hl2) / interval).round(asset_pair.cost_decimals)

    create!(asset_pair:, duration:, range_position:, interval:, value:)
  end
end
