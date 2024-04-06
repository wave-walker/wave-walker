# frozen_string_literal: true

class NextNewOhlcRangeValueService
  def self.call(**) = new(**).call

  def initialize(asset_pair:, duration:)
    @asset_pair = asset_pair
    @duration = duration
  end

  def call
    return last_ohlc.range.next if last_ohlc

    OhlcRangeValue.at(time: first_trade.created_at, duration:)
  end

  private

  attr_reader :asset_pair, :duration

  def last_ohlc
    Ohlc.where(asset_pair:, duration:).last
  end

  def first_trade
    asset_pair.trades.first
  end
end
