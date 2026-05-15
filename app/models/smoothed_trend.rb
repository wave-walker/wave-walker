# frozen_string_literal: true

class SmoothedTrend < ApplicationRecord
  include DurationConcern
  include RangeConcern

  belongs_to :asset_pair
  belongs_to :ohlc, foreign_key: %i[asset_pair_id iso8601_duration range_position],
                    inverse_of: :smoothed_trend

  enum :trend, { bearish: 'bearish', neutral: 'neutral', bullish: 'bullish' }

  # SMMA intervals used for trend calculation
  SMMA_FAST_INTERVAL = 16
  SMMA_MEDIUM_FAST_INTERVAL = 19
  SMMA_MEDIUM_SLOW_INTERVAL = 25
  SMMA_SLOW_INTERVAL = 28

  scope :recent_daily_flips, -> { by_duration_before(1.day, 1.week.ago).where(flip: true) }
  scope :by_duration_before, lambda { |duration, time|
    by_duration(duration).where(range_position: OhlcRangeValue.at(duration:, time:).position...)
  }

  def self.bulk_create_for_duration(asset_pair:, duration:)
    query = BulkQuery.new(asset_pair:, duration:)
    return if query.empty?

    builder = BulkBuilder.new(previous_trend: query.last_trend&.trend)

    query.each_batch do |smmas_by_position|
      records = builder.build_records(smmas_by_position, asset_pair:, duration:)
      insert_all!(records) unless records.empty? # rubocop:disable Rails/SkipsModelValidations
    end
  end

  private_class_method def self.calculate_trend(fast_smma, medium_fast_smma, medium_slow_smma, slow_smma)
    bullish = fast_smma > slow_smma
    neutral_up = (fast_smma < medium_fast_smma) == bullish
    neutral_down = (medium_slow_smma < slow_smma) == bullish
    neutral = neutral_up || neutral_down

    return 'neutral' if neutral
    return 'bullish' if bullish

    'bearish'
  end
end
