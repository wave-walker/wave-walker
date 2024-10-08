# frozen_string_literal: true

trend_colors = {
  'bearish' => '#1700FF',
  'bullish' => '#BEFF00',
  'neutral' => '#808080'
}.freeze

json.candles do
  json.array!(@ohlcs) do |ohlc|
    json.extract! ohlc, :open, :high, :low, :close
    json.time ohlc.range.end.to_i
  end
end

json.volumes do
  json.array!(@ohlcs) do |ohlc|
    json.value ohlc.volume.to_f
    json.time ohlc.range.end.to_i
    json.color ohlc.open < ohlc.close ? :green : :red
  end
end

trends = @ohlcs.filter_map(&:smoothed_trend)

json.fastTrends do
  json.array!(trends) do |trend|
    json.value trend.fast_smma
    json.color trend_colors.fetch(trend.trend)
    json.time trend.range.end.to_i
  end
end

json.slowTrends do
  json.array!(trends) do |trend|
    json.value trend.slow_smma
    json.color trend_colors.fetch(trend.trend)
    json.time trend.range.end.to_i
  end
end

json.backtestTrades do
  json.array!(@ohlcs.filter_map(&:backtest_trade)) do |trade|
    json.value trade.price.to_f
    json.time trade.range.end.to_i

    position = "Position size: #{number_to_currency(trade.backtest.current_value)}"

    if trade.buy?
      json.position :belowBar
      json.color :green
      json.shape :arrowUp
      json.text "BUY @ #{number_to_currency(trade.price)} #{position}"
    else
      json.position :aboveBar
      json.color :red
      json.shape :arrowDown
      json.text "SELL @ #{number_to_currency(trade.price)} #{position}"
    end
  end
end

json.meta do
  json.nextRangePosition @ohlcs.any? ? @ohlcs.first.range_position - 1 : nil
end
