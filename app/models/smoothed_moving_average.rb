# frozen_string_literal: true

class SmoothedMovingAverage < ApplicationRecord
  INTERVALS = [16, 19, 25, 28].freeze

  include DurationConcern

  belongs_to :asset_pair

  scope :with_generated_intervals, lambda {
    where(interval: INTERVALS).joins(<<~SQL.squish)
      INNER JOIN (
        #{where(interval: INTERVALS)
            .select(:asset_pair_id, :iso8601_duration, :range_position)
            .group(:asset_pair_id, :iso8601_duration, :range_position)
            .having('COUNT(DISTINCT "interval") = ?', INTERVALS.count)
            .to_sql}
      ) with_generated_intervals
      USING (asset_pair_id, iso8601_duration, range_position)
    SQL
  }

  def self.bulk_create(asset_pair)
    Ohlc::DURATIONS.each do |duration|
      INTERVALS.each { |interval| bulk_create_interval(asset_pair:, duration:, interval:) }
    end
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

  def self.bulk_create_interval(asset_pair:, duration:, interval:) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
    start_smma = order(range_position: :desc).find_by(asset_pair:, iso8601_duration: duration.iso8601, interval:) ||
                 create_initial_sma(asset_pair:, duration:, interval:)

    return unless start_smma

    range_position = start_smma.range_position
    value = start_smma.value

    Ohlc.where(asset_pair:, range_position: (range_position + 1)..).by_duration(duration).in_batches do |ohlcs|
      records = ohlcs.map do |ohlc|
        value = ((value * (interval - 1)) + ohlc.hl2) / interval
        range_position += 1

        { asset_pair_id: asset_pair.id, iso8601_duration: duration.iso8601, range_position:, interval:, value: }
      end
      insert_all! records # rubocop:disable Rails/SkipsModelValidations
    end
  end
end
