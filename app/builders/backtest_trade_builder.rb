# frozen_string_literal: true

class BacktestTradeBuilder
  SLIPPAGE = 0.02
  FEE = 0.02

  def self.build(**) = new(**).build

  def initialize(ohlc:, trade_type:, current_quantity:)
    @ohlc = ohlc
    @trade_type = trade_type
    @current_quantity = current_quantity
  end

  def build
    {
      asset_pair_id:,
      iso8601_duration:,
      fee:,
      quantity:,
      price:,
      trade_type:,
      range_position:
    }
  end

  private

  attr_reader :ohlc, :trade_type, :current_quantity

  def asset_pair_id = ohlc.asset_pair_id
  def iso8601_duration = ohlc.iso8601_duration
  def range_position = ohlc.range_position
  def price = ohlc.close * (1 + SLIPPAGE)
  def buy? = trade_type == :buy
  def cost_decimals = ohlc.asset_pair.cost_decimals

  def fee
    if buy?
      current_quantity * FEE
    else
      current_quantity * FEE * price
    end.round(cost_decimals)
  end

  def quantity
    if buy?
      current_quantity * (1 - FEE) / price
    else
      current_quantity * price * (1 - FEE)
    end.round(cost_decimals)
  end
end
