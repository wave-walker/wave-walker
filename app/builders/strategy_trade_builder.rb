# frozen_string_literal: true

class StrategyTradeBuilder
  def self.build(**) = new(**).build

  def initialize(ohlc:, strategy_backtest:, action:, slippage:, fee:)
    @ohlc               = ohlc
    @strategy_backtest  = strategy_backtest
    @action             = action
    @slippage           = slippage
    @fee_rate           = fee
  end

  def build
    {
      strategy_id:,
      asset_pair_id:,
      iso8601_duration:,
      range_position:,
      action:,
      price:,
      volume:,
      fee:
    }
  end

  private

  attr_reader :ohlc, :strategy_backtest, :action, :slippage, :fee_rate

  def strategy_id       = strategy_backtest.strategy_id
  def asset_pair_id     = ohlc.asset_pair_id
  def iso8601_duration  = ohlc.iso8601_duration
  def range_position    = ohlc.range_position
  def buy?              = action == :buy
  def cost_decimals     = strategy_backtest.asset_pair.cost_decimals
  def usd_volume        = strategy_backtest.usd_volume
  def token_volume      = strategy_backtest.token_volume

  def price
    return ohlc.close * (1 + slippage) if buy?

    ohlc.close * (1 - slippage)
  end

  def total_volume
    if buy?
      usd_volume / price
    else
      token_volume
    end
  end

  def volume  = (total_volume * (1 - fee_rate)).round(cost_decimals)
  def fee     = (total_volume * price * fee_rate).round(cost_decimals)
end
