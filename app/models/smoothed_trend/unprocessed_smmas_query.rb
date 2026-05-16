# frozen_string_literal: true

class SmoothedTrend
  class UnprocessedSmmasQuery
    def initialize(asset_pair:, duration:)
      @asset_pair = asset_pair
      @iso8601_duration = duration.iso8601
    end

    def call
      SmoothedMovingAverage.from(build_subquery, :smoothed_moving_averages)
                           .order(:range_position)
    end

    private

    attr_reader :asset_pair, :iso8601_duration

    def build_subquery
      base_relation.select(:asset_pair_id, :iso8601_duration, :range_position, :interval)
                   .select('smoothed_moving_averages.value AS fast_value')
                   .where(interval: SmoothedTrend::SMMA_FAST_INTERVAL)
                   .where('smoothed_moving_averages.range_position > ?', lastest_smoothed_trend)
                   .merge(join_interval(SmoothedTrend::SMMA_MEDIUM_FAST_INTERVAL, 'medium_fast_value'))
                   .merge(join_interval(SmoothedTrend::SMMA_MEDIUM_SLOW_INTERVAL, 'medium_slow_value'))
                   .merge(join_interval(SmoothedTrend::SMMA_SLOW_INTERVAL, 'slow_value'))
    end

    def base_relation
      SmoothedMovingAverage.where(asset_pair:, iso8601_duration:)
    end

    def lastest_smoothed_trend
      @lastest_smoothed_trend ||= SmoothedTrend.where(asset_pair:, iso8601_duration:).maximum(:range_position) || 0
    end

    def join_interval(interval, name)
      alias_table = "value_#{interval.to_i}s"

      base_relation.joins(<<~SQL.squish).select("#{alias_table}.value AS #{name}")
        INNER JOIN (#{base_relation.where(interval:).to_sql}) #{alias_table}
        ON smoothed_moving_averages.range_position = #{alias_table}.range_position
      SQL
    end
  end
end
