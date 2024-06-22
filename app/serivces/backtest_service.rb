# frozen_string_literal: true

class BacktestService
  def self.call(**) = new(**).call

  def initialize(backtest:, smoothed_trends:)
    @backtest = backtest
    @smoothed_trends = smoothed_trends
  end

  def call
    ActiveRecord::Base.transaction do
      BacktestTrade.insert_all!(trades) # rubocop:disable Rails/SkipsModelValidations
      backtest.update!(last_range_position:, current_value:)
    end
  end

  private

  attr_reader :backtest, :smoothed_trends

  def last_range_position = smoothed_trends.last.range_position
  def asset_pair_id = backtest.asset_pair_id
  def iso8601_duration = backtest.iso8601_duration
  def base_trade_params = { asset_pair_id:, iso8601_duration: }
  def cost_decimals = backtest.asset_pair.cost_decimals
  def last_price = smoothed_trends.last.ohlc.close
  def current_value = backtest.usd_quantity + (backtest.token_quantity * last_price)

  def build_buy(ohlc)
    return if backtest.usd_quantity.zero?

    trade = BacktestTradeBuilder.build(ohlc:, trade_type: :buy, current_quantity: backtest.usd_quantity)

    backtest.usd_quantity = 0
    backtest.token_quantity = trade.fetch(:quantity)

    trade
  end

  def build_sell(ohlc)
    return if backtest.token_quantity.zero?

    trade = BacktestTradeBuilder.build(ohlc:, trade_type: :sell, current_quantity: backtest.token_quantity)

    backtest.usd_quantity = trade.fetch(:quantity)
    backtest.token_quantity = 0

    trade
  end

  def trades
    smoothed_trends.filter(&:flip?).filter_map do |smoothed_trend|
      ohlc = smoothed_trend.ohlc

      if smoothed_trend.bullish?
        build_buy(ohlc)
      elsif smoothed_trend.neutral?
        build_sell(ohlc)
      end
    end
  end
end
