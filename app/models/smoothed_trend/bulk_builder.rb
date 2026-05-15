# frozen_string_literal: true

class SmoothedTrend
  class BulkBuilder
    def initialize(previous_trend:)
      @previous_trend = previous_trend
    end

    def build_records(smmas_by_position, asset_pair:, duration:)
      iso8601_duration = duration.iso8601

      smmas_by_position.filter_map do |range_position, smmas|
        smma_values = SmmaValues.from_array(smmas)

        next unless smma_values.complete?

        current_trend = SmoothedTrend.send(:calculate_trend,
                                           smma_values.fast,
                                           smma_values.medium_fast,
                                           smma_values.medium_slow,
                                           smma_values.slow)

        flip = @previous_trend.nil? || @previous_trend != current_trend

        @previous_trend = current_trend

        {
          asset_pair_id: asset_pair.id,
          iso8601_duration:,
          range_position:,
          fast_smma: smma_values.fast,
          slow_smma: smma_values.slow,
          trend: current_trend,
          flip:,
          created_at: Time.current
        }
      end
    end
  end
end
