# frozen_string_literal: true

class SmoothedTrendService
  def self.call(ohlcs)
    return if ohlcs.empty?

    ohlcs = ohlcs.sort_by(&:range_position)
    trend_cache = build_trend_cache(ohlcs)
    intervals = SmoothedMovingAverage::INTERVALS

    # Pre-load SMMAs for all ohlcs in one query
    smma_values = load_smma_values(ohlcs)
    trend_attrs = []

    ActiveRecord::Base.transaction do
      ohlcs.each do |ohlc|
        values = smma_values[[ohlc.asset_pair_id, ohlc.iso8601_duration, ohlc.range_position]]
        next unless values && (intervals - values.keys).empty?

        fast_smma = values[16]
        slow_smma = values[28]
        medium_fast_smma = values[19]
        medium_slow_smma = values[25]

        trend = compute_trend(fast_smma, slow_smma, medium_fast_smma, medium_slow_smma)
        flip = compute_flip(ohlc, trend, trend_cache)
        trend_cache[[ohlc.asset_pair_id, ohlc.iso8601_duration, ohlc.range_position]] = trend.to_s

        trend_attrs << {
          asset_pair_id: ohlc.asset_pair_id,
          iso8601_duration: ohlc.iso8601_duration,
          range_position: ohlc.range_position,
          fast_smma: fast_smma,
          slow_smma: slow_smma,
          trend: trend,
          flip: flip,
          created_at: Time.current
        }
      end

      SmoothedTrend.insert_all!(trend_attrs) if trend_attrs.any?
    end
  end

  private_class_method def self.load_smma_values(ohlcs)
    first = ohlcs.first
    last = ohlcs.last

    SmoothedMovingAverage.where(
      asset_pair_id: first.asset_pair_id,
      iso8601_duration: first.iso8601_duration,
      range_position: first.range_position..last.range_position,
      interval: SmoothedMovingAverage::INTERVALS
    ).each_with_object({}) do |sma, cache|
      key = [sma.asset_pair_id, sma.iso8601_duration, sma.range_position]
      cache[key] ||= {}
      cache[key][sma.interval] = sma.value
    end
  end

  private_class_method def self.build_trend_cache(ohlcs)
    return {} if ohlcs.empty?

    first = ohlcs.first
    last = ohlcs.last

    SmoothedTrend.where(
      asset_pair_id: first.asset_pair_id,
      iso8601_duration: first.iso8601_duration,
      range_position: (first.range_position - 1)..(last.range_position - 1)
    ).each_with_object({}) do |st, cache|
      cache[[st.asset_pair_id, st.iso8601_duration, st.range_position]] = st.trend
    end
  end

  private_class_method def self.compute_trend(fast_smma, slow_smma, medium_fast_smma, medium_slow_smma)
    bullish = fast_smma > slow_smma

    return :neutral if (fast_smma < medium_fast_smma) == bullish || (medium_slow_smma < slow_smma) == bullish
    return :bullish if bullish
    :bearish
  end

  private_class_method def self.compute_flip(ohlc, trend, trend_cache)
    previous_trend = trend_cache[[ohlc.asset_pair_id, ohlc.iso8601_duration, ohlc.range_position - 1]]
    previous_trend != trend.to_s
  end
end