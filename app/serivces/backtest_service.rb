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
  def current_value = backtest.usd_volume + (backtest.token_volume * last_price)

  def build_trade(smoothed_trend) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    return if backtest.token_volume.zero? && smoothed_trend.neutral?
    return if backtest.usd_volume.zero? && smoothed_trend.bullish?

    action = smoothed_trend.bullish? ? :buy : :sell
    ohlc = smoothed_trend.ohlc

    BacktestTradeBuilder.build(ohlc:, backtest:, action:).tap do |trade_params|
      price, volume = trade_params.values_at(:price, :volume)

      if smoothed_trend.bullish?
        backtest.usd_volume   = 0
        backtest.token_volume = volume
      else
        backtest.token_volume = 0
        backtest.usd_volume   = volume * price
      end
    end
  end

  def trades
    smoothed_trends.filter(&:flip?).filter_map do |smoothed_trend|
      next unless smoothed_trend.bullish? || smoothed_trend.neutral?

      build_trade(smoothed_trend)
    end
  end
end
