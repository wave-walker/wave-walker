# frozen_string_literal: true

class CreateSmoothedMovingAveragesService
  INTERVALS = [16, 28, 19, 25].freeze

  def self.call(ohlcs)
    return if ohlcs.empty?

    ohlcs = ohlcs.sort_by(&:range_position)
    existing_smmas = load_existing_smmas(ohlcs)
    attrs = []

    ohlcs.each do |ohlc|
      INTERVALS.each do |interval|
        smma_value = compute_smma(ohlc, interval, existing_smmas)
        next unless smma_value

        key = [ohlc.asset_pair_id, ohlc.iso8601_duration, ohlc.range_position, interval]
        existing_smmas[key] = smma_value

        attrs << {
          asset_pair_id: ohlc.asset_pair_id,
          iso8601_duration: ohlc.iso8601_duration,
          range_position: ohlc.range_position,
          interval: interval,
          value: smma_value,
          created_at: Time.current
        }
      end
    end

    SmoothedMovingAverage.insert_all!(attrs) if attrs.any?
  end

  private_class_method def self.load_existing_smmas(ohlcs)
    first = ohlcs.first
    min_position = first.range_position

    SmoothedMovingAverage
      .where(
        asset_pair_id: first.asset_pair_id,
        iso8601_duration: first.iso8601_duration,
        interval: INTERVALS
      )
      .where(range_position: ...min_position)
      .each_with_object({}) do |sma, cache|
        cache[[sma.asset_pair_id, sma.iso8601_duration, sma.range_position, sma.interval]] = sma.value
      end
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
