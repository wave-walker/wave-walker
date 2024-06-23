# frozen_string_literal: true

class BacktestTradeBuilder
  SLIPPAGE = 0.02
  FEE = 0.02

  def self.build(**) = new(**).build

  def initialize(ohlc:, backtest:, action:)
    @ohlc = ohlc
    @action = action
    @backtest = backtest
  end

  def build
    {
      asset_pair_id:,
      iso8601_duration:,
      fee:,
      volume:,
      price:,
      action:,
      range_position:
    }
  end

  private

  attr_reader :ohlc, :action, :backtest

  def asset_pair_id = ohlc.asset_pair_id
  def iso8601_duration = ohlc.iso8601_duration
  def range_position = ohlc.range_position
  def buy? = action == :buy
  def cost_decimals = backtest.asset_pair.cost_decimals
  def usd_volume = backtest.usd_volume
  def token_volume = backtest.token_volume
  # TODO: This must be rounded by the token decimal
  def volume = (totoal_volume * (1 - FEE)).round(cost_decimals)
  def fee = (totoal_volume * price * FEE).round(cost_decimals)

  def price
    return ohlc.close * (1 + SLIPPAGE) if buy?

    ohlc.close * (1 - SLIPPAGE)
  end

  def totoal_volume
    if buy?
      usd_volume / price
    else
      token_volume
    end
  end
end
