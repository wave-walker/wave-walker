# frozen_string_literal: true

class SmoothedMovingAverage < ApplicationRecord
  include DurationConcern

  belongs_to :asset_pair

  def self.latest_range_position(asset_pair:, duration:, interval:)
    by_duration(duration).where(asset_pair:, interval:).maximum(:range_position)
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

  def self.bulk_create(asset_pair:, duration:, interval:)
    start_smma = order(range_position: :desc).find_by(asset_pair:, iso8601_duration: duration.iso8601, interval:) ||
                 create_initial_sma(asset_pair:, duration:, interval:)

    return unless start_smma

    Ohlc.where(asset_pair:, range_position: (start_smma.range_position + 1)..).by_duration(duration).in_batches do |ohlcs|
      ohlcs.each { SmoothedMovingAverageService.call(ohlc: it, interval:) }
    end
  end
end
