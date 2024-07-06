# frozen_string_literal: true

class BacktestService
  def self.call(**) = new(**).call

  def initialize(backtest:, smoothed_trends:)
    @backtest = backtest
    @ohlcs = smoothed_trends.map(&:ohlc)
  end

  def call
    ohlcs.each do |ohlc|
      BacktestTradeService.call(backtest:, ohlc:)
    end

    backtest.update!(last_range_position: ohlcs.last.range_position, current_value:)
  end

  private

  attr_reader :backtest, :ohlcs

  def last_price = ohlcs.last.close
  def current_value = backtest.usd_volume + (backtest.token_volume * last_price)
end
