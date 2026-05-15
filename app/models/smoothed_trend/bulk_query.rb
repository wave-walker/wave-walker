# frozen_string_literal: true

class SmoothedTrend
  class BulkQuery
    def initialize(asset_pair:, duration:)
      @asset_pair = asset_pair
      @duration = duration
    end

    def last_trend
      SmoothedTrend.where(asset_pair: @asset_pair, iso8601_duration: @duration.iso8601)
                   .order(range_position: :desc)
                   .first
    end

    delegate :empty?, to: :smma_scope

    def each_batch(&block)
      smma_scope.in_batches do |batch|
        grouped = batch.group_by(&:range_position)
        block.call(grouped)
      end
    end

    private

    def start_position
      last_trend ? last_trend.range_position + 1 : 0
    end

    def smma_scope
      SmoothedMovingAverage.with_generated_intervals
                           .where(asset_pair: @asset_pair)
                           .by_duration(@duration)
                           .where(range_position: start_position..)
                           .order(:range_position)
    end
  end
end
