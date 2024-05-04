# frozen_string_literal: true

class AssetPairChartComponent < ViewComponent::Base
  TREND_COLORS = {
    'bearish' => '#1700FF',
    'bullish' => '#BEFF00',
    'neutral' => '#808080'
  }.freeze

  def initialize(asset_pair:, duration:)
    @asset_pair = asset_pair
    @duration = duration
    super
  end

  def id
    "asset_pair_chard_#{asset_pair.id}"
  end

  def tile
    "#{asset_pair.name} #{duration}"
  end

  def candlestick_series
    ohlcs.map do |ohlc|
      {
        time: ohlc.range.end.to_i,
        open: ohlc.open,
        high: ohlc.high,
        low: ohlc.low,
        close: ohlc.close
      }
    end
  end

  def smoothed_trend_slow_series
    ohlcs.filter(&:smoothed_trend).map do |ohlc|
      smoothed_trend = ohlc.smoothed_trend

      {
        value: smoothed_trend.slow_smma,
        color: TREND_COLORS.fetch(smoothed_trend.trend),
        time: ohlc.range.end.to_i
      }
    end
  end

  def smoothed_trend_fast_series
    ohlcs.filter(&:smoothed_trend).map do |ohlc|
      smoothed_trend = ohlc.smoothed_trend
      {
        value: smoothed_trend.fast_smma,
        color: TREND_COLORS.fetch(smoothed_trend.trend),
        time: ohlc.range.end.to_i
      }
    end
  end

  def volume_series
    ohlcs.map do |ohlc|
      color = ohlc.open < ohlc.close ? 'green' : 'red'
      { time: ohlc.range.end.to_i, value: ohlc.volume, color: }
    end
  end

  def price_format
    {
      type: 'price',
      precision: asset_pair.cost_decimals,
      minMove: 1.0 / (10**asset_pair.cost_decimals)
    }
  end

  private

  attr_reader :asset_pair, :duration

  def ohlcs = Ohlc.by_duration(duration).where(asset_pair:).includes(:smoothed_trend).last(300)
end
