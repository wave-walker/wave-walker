# frozen_string_literal: true

class BacktestTradeService
  def self.call(**) = new(**).call

  def initialize(backtest:, ohlc:)
    @backtest = backtest
    @ohlc = ohlc
  end

  def call
    return unless trade?

    ActiveRecord::Base.transaction do
      backtest_trade.save!
      backtest.update!(
        last_range_position: ohlc.range_position,
        usd_volume:, token_volume:
      )
    end
  end

  private

  attr_reader :backtest, :ohlc

  def smoothed_trend = ohlc.smoothed_trend

  def trade?
    return false unless smoothed_trend.flip?

    (smoothed_trend.neutral? && !backtest.token_volume.zero?) ||
      (smoothed_trend.bullish? && !backtest.usd_volume.zero?)
  end

  def action = smoothed_trend.bullish? ? :buy : :sell
  def price = ohlc.close

  def backtest_trade
    @backtest_trade ||= BacktestTrade.new(BacktestTradeBuilder.build(ohlc:, backtest:, action:))
  end

  def usd_volume
    return 0 if smoothed_trend.bullish?

    backtest_trade.volume * backtest_trade.price
  end

  def token_volume
    return backtest_trade.volume if smoothed_trend.bullish?

    0
  end
end
