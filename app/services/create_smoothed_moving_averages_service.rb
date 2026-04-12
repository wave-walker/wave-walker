# frozen_string_literal: true

class CreateSmoothedMovingAveragesService
  def self.call(ohlcs, intervals)
    cache = {}
    attrs = []

    ohlcs.each do |ohlc|
      intervals.each do |interval|
        value = compute_smma(ohlc, interval, cache)
        next unless value

        cache[[ohlc.asset_pair_id, ohlc.iso8601_duration, ohlc.range_position, interval]] = value

        attrs << {
          asset_pair_id: ohlc.asset_pair_id,
          iso8601_duration: ohlc.iso8601_duration,
          range_position: ohlc.range_position,
          interval: interval,
          value: value,
          created_at: Time.current
        }
      end
    end

    SmoothedMovingAverage.upsert_all(attrs, unique_by: %i[asset_pair_id iso8601_duration range_position interval]) if attrs.any?
  end

  private_class_method def self.compute_smma(ohlc, interval, cache)
    decimals = ohlc.asset_pair.cost_decimals
    value = (calculate_smma(ohlc, interval, cache) || calculate_sma(ohlc, interval))&.round(decimals)
    value
  end

  private_class_method def self.calculate_smma(ohlc, interval, cache)
    last_smma_value = cache[[ohlc.asset_pair_id, ohlc.iso8601_duration, ohlc.range_position - 1, interval]]
    return unless last_smma_value

    ((last_smma_value * (interval - 1)) + ohlc.hl2) / interval
  end

  private_class_method def self.calculate_sma(ohlc, interval)
    previous_ohlcs = ohlc.previous_ohlcs.first(interval).to_a
    return if previous_ohlcs.count != interval

    previous_ohlcs.sum(&:hl2) / interval
  end
end
