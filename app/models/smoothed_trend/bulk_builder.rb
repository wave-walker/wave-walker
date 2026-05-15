# frozen_string_literal: true

class SmoothedTrend
  class BulkBuilder
    attr_reader :previous_trend

    def initialize(previous_trend:)
      @previous_trend = previous_trend
    end

    def build_records(smmas_by_position, asset_pair:, duration:)
      return [] if smmas_by_position.empty?

      smmas_by_position.filter_map do |range_position, smmas|
        build_record(range_position, smmas, asset_pair:, duration:)
      end
    end

    private

    def build_record(range_position, smmas, asset_pair:, duration:)
      values = SmmaValues.from_array(smmas)
      return unless values.complete?

      trend = calculate_trend(values)
      flip = previous_trend.nil? || previous_trend != trend
      @previous_trend = trend

      record_hash(range_position, values, trend:, flip:, asset_pair:, duration:)
    end

    def record_hash(range_position, values, trend:, flip:, asset_pair:, duration:) # rubocop:disable Metrics/ParameterLists
      {
        asset_pair_id: asset_pair.id,
        iso8601_duration: duration.iso8601,
        range_position:,
        fast_smma: values.fast,
        slow_smma: values.slow,
        trend:,
        flip:,
        created_at: Time.current
      }
    end

    def calculate_trend(values)
      return 'neutral' if neutral?(values)
      return 'bullish' if bullish?(values)

      'bearish'
    end

    def bullish?(values)
      values.fast > values.slow
    end

    def neutral_up?(values)
      (values.fast < values.medium_fast) == bullish?(values)
    end

    def neutral_down?(values)
      (values.medium_slow < values.slow) == bullish?(values)
    end

    def neutral?(values)
      neutral_up?(values) || neutral_down?(values)
    end
  end
end
