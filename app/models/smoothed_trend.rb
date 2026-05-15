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

  # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/MethodLength,Metrics/PerceivedComplexity
  def self.bulk_create_for_duration(asset_pair:, duration:)
    iso8601_duration = duration.iso8601

    # Get the starting position (after last existing SmoothedTrend)
    last_trend = where(asset_pair:, iso8601_duration:).order(range_position: :desc).first
    start_position = last_trend ? last_trend.range_position + 1 : 0

    # Get SMMAs with all 4 intervals present
    base_scope = SmoothedMovingAverage.with_generated_intervals
                                      .where(asset_pair:)
                                      .by_duration(duration)
                                      .where(range_position: start_position..)
                                      .order(:range_position)

    return if base_scope.empty?

    previous_trend = last_trend&.trend

    base_scope.in_batches do |batch|
      records = []

      # Group by range_position to get all 4 SMMA values for each position
      batch.group_by(&:range_position).each do |range_position, smmas|
        # Extract the 4 SMMA values
        smma_hash = smmas.index_by(&:interval)
        fast_smma = smma_hash[SMMA_FAST_INTERVAL]&.value
        medium_fast_smma = smma_hash[SMMA_MEDIUM_FAST_INTERVAL]&.value
        medium_slow_smma = smma_hash[SMMA_MEDIUM_SLOW_INTERVAL]&.value
        slow_smma = smma_hash[SMMA_SLOW_INTERVAL]&.value

        # Skip if any SMMA value is nil
        next if fast_smma.nil? || medium_fast_smma.nil? || medium_slow_smma.nil? || slow_smma.nil?

        # Calculate trend using same logic as SmoothedTrendService
        current_trend = calculate_trend(fast_smma, medium_fast_smma, medium_slow_smma, slow_smma)

        # Calculate flip - true if no previous trend or trend changed
        flip = previous_trend.nil? || previous_trend != current_trend

        records << {
          asset_pair_id: asset_pair.id,
          iso8601_duration:,
          range_position:,
          fast_smma:,
          slow_smma:,
          trend: current_trend,
          flip:,
          created_at: Time.current
        }

        previous_trend = current_trend
      end

      insert_all! records unless records.empty? # rubocop:disable Rails/SkipsModelValidations
    end
  end
  # rubocop:enable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/MethodLength,Metrics/PerceivedComplexity

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
