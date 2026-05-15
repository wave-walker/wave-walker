# frozen_string_literal: true

class SmoothedTrend
  class BulkQuery
    def initialize(asset_pair:, duration:)
      @asset_pair = asset_pair
      @duration = duration
      @iso8601_duration = duration.iso8601
    end

    def last_trend
      SmoothedTrend.where(asset_pair:, iso8601_duration:).order(range_position: :desc).first
    end

    def empty?
      each_batch.first.nil?
    end

    def each_batch(&)
      return to_enum(:each_batch) unless block_given?

      base_relation.find_in_batches(batch_size: 1000) do |batch|
        grouped = group_smmas(batch)
        yield grouped if grouped.any?
      end
    end

    private

    attr_reader :asset_pair, :duration, :iso8601_duration

    def base_relation
      relation = SmoothedMovingAverage.where(asset_pair:, iso8601_duration:)
                                      .where(interval: SmoothedTrend::SMMA_FAST_INTERVAL)
      relation = relation.where('range_position > ?', last_trend.range_position) if last_trend
      relation
    end

    def group_smmas(batch)
      positions = batch.map(&:range_position)
      all_smmas = SmoothedMovingAverage.where(asset_pair:, iso8601_duration:)
                                       .where(range_position: positions)
                                       .order(:range_position)
      all_smmas.group_by(&:range_position).select { |_, smmas| smmas.size == 4 }
    end
  end
end
