# frozen_string_literal: true

class AssetPairChartComponent < ViewComponent::Base
  def initialize(asset_pair:, timeframe:)
    @asset_pair = asset_pair
    @timeframe = timeframe
    super
  end

  def tile
    "#{asset_pair.name} #{timeframe}"
  end

  def candlestick_series
    ohlcs.map do |ohlc|
      {
        time: ohlc.range.end,
        open: ohlc.open,
        high: ohlc.high,
        low: ohlc.low,
        close: ohlc.close
      }
    end
  end

  def volume_series
    ohlcs.map do |ohlc|
      color = ohlc.open < ohlc.close ? 'green' : 'red'
      { time: ohlc.range.end, value: ohlc.volume, color: }
    end
  end

  private

  attr_reader :asset_pair, :timeframe

  def ohlcs = Ohlc.where(asset_pair:, timeframe:).last(300)
end
