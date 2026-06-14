# frozen_string_literal: true

class NewSmoothedTendParameterQuery
  def initialize(asset_pair:, duration:)
    @asset_pair = asset_pair
    @iso8601_duration = duration.iso8601
  end

  def in_batches
    SmoothedMovingAverage.from(build_subquery, :smoothed_moving_averages)
                         .order(:range_position)
                         # `in_batches` build large OR conditions per row instead of
                         # optimized tuple comparisons.
                         # TODO: Find a way to make range_position the cursor.
                         .in_batches(of: 100) do |smmas|
                           yield smmas.map { build_params(it) }
                         end
  end

  private

  attr_reader :asset_pair, :iso8601_duration
  attr_accessor :last_trend

  def build_params(trend_data) # rubocop:disable Metrics/MethodLength
    trend = calulate_trend(trend_data)
    flip = !last_trend.nil? && last_trend != trend
    self.last_trend = trend

    {
      range_position: trend_data.range_position,
      asset_pair_id: asset_pair.id,
      iso8601_duration:,
      trend:,
      flip:,
      fast_smma: trend_data.fast_value,
      slow_smma: trend_data.slow_value
    }
  end

  def calulate_trend(trend_data)
    if (trend_data.fast_value < trend_data.medium_fast_value) || (trend_data.medium_slow_value < trend_data.slow_value)
      :neutral
    elsif trend_data.fast_value > trend_data.slow_value
      :bullish
    else
      :bearish
    end
  end

  def build_subquery
    base_relation.select(:asset_pair_id, :iso8601_duration, :range_position, :interval)
                 .select('smoothed_moving_averages.value AS fast_value')
                 .where(interval: SmoothedTrend::SMMA_FAST_INTERVAL)
                 .where('smoothed_moving_averages.range_position > ?', latest_range_position)
                 .merge(join_interval(SmoothedTrend::SMMA_MEDIUM_FAST_INTERVAL, 'medium_fast_value'))
                 .merge(join_interval(SmoothedTrend::SMMA_MEDIUM_SLOW_INTERVAL, 'medium_slow_value'))
                 .merge(join_interval(SmoothedTrend::SMMA_SLOW_INTERVAL, 'slow_value'))
  end

  def base_relation
    SmoothedMovingAverage.where(asset_pair:, iso8601_duration:)
  end

  def latest_range_position = lastest_smoothed_trend&.range_position || 0

  def lastest_smoothed_trend
    return @lastest_smoothed_trend if defined?(@lastest_smoothed_trend)

    @lastest_smoothed_trend = SmoothedTrend.order(range_position: :desc).find_by(asset_pair:, iso8601_duration:)
  end

  def join_interval(interval, name)
    alias_table = "value_#{interval.to_i}s"

    base_relation.joins(<<~SQL.squish).select("#{alias_table}.value AS #{name}")
      INNER JOIN (#{base_relation.where(interval:).to_sql}) #{alias_table}
      ON smoothed_moving_averages.range_position = #{alias_table}.range_position
    SQL
  end
end
