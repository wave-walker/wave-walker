# frozen_string_literal: true

require 'test_helper'

class BacktestServiceTest < ActiveSupport::TestCase
  test 'trades on a bullish trend flip' do
    ohlc = ohlcs(:atom20230101)
    ohlc.update!(close: 100)
    backtest = backtests(:atom)

    smoothed_trend = SmoothedTrendService.call(ohlc)
    smoothed_trend.update!(trend: :bullish, flip: true)

    assert_changes 'BacktestTrade.count', to: 1 do
      BacktestService.call(backtest:, smoothed_trends: [smoothed_trend])
    end

    trade = BacktestTrade.last
    assert_equal trade.asset_pair_id, backtest.asset_pair_id
    assert_equal trade.iso8601_duration, backtest.iso8601_duration
    assert_equal trade.range_position, ohlc.range_position
    assert_equal trade.action, 'buy'
    assert_equal trade.volume, 96.078431
    assert_equal trade.fee, 200
    assert_equal trade.price, 102
  end

  test 'sells on a neutral trend flip' do
    ohlc = ohlcs(:atom20230101)
    ohlc.update!(close: 100)
    backtest = backtests(:atom)
    backtest.update!(usd_volume: 0, token_volume: 1000)

    smoothed_trend = SmoothedTrendService.call(ohlc)
    smoothed_trend.update!(trend: :neutral, flip: true)

    assert_changes 'BacktestTrade.count', to: 1 do
      BacktestService.call(backtest:, smoothed_trends: [smoothed_trend])
    end

    trade = BacktestTrade.last
    assert_equal trade.asset_pair_id, backtest.asset_pair_id
    assert_equal trade.iso8601_duration, backtest.iso8601_duration
    assert_equal trade.range_position, ohlc.range_position
    assert_equal 'sell', trade.action
    assert_equal trade.volume, 980
    assert_equal trade.fee, 1960
    assert_equal trade.price, 98
  end

  test 'sells nothing when nothing is invested' do
    backtest = backtests(:atom)
    backtest.token_volume = 0
    ohlc = Ohlc.new(close: 100, range_position: 1)

    smoothed_trends = [SmoothedTrend.new(trend: :bearish, flip: true, range_position: 1, ohlc:)]

    assert_no_changes 'BacktestTrade.count' do
      BacktestService.call(backtest:, smoothed_trends:)
    end
  end

  test 'buys nothing when no usd is available' do
    backtest = backtests(:atom)
    backtest.usd_volume = 0
    ohlc = Ohlc.new(close: 100, range_position: 1)

    smoothed_trends = [SmoothedTrend.new(trend: :bullish, flip: true, range_position: 1, ohlc:)]

    assert_no_changes 'BacktestTrade.count' do
      BacktestService.call(backtest:, smoothed_trends:)
    end
  end

  test 'records the last backtest position' do
    backtest = backtests(:atom)
    ohlc = Ohlc.new(close: 100, range_position: 5)

    smoothed_trends = [
      SmoothedTrend.new(range_position: 3),
      SmoothedTrend.new(range_position: 4),
      SmoothedTrend.new(range_position: 5, ohlc:)
    ]

    assert_changes 'backtest.reload.last_range_position', to: 5 do
      BacktestService.call(backtest:, smoothed_trends:)
    end
  end

  test 'records the current value of the backtest' do
    backtest = backtests(:atom)
    backtest.update!(usd_volume: 5, token_volume: 5)
    ohlc = Ohlc.new(close: 100, range_position: 5)

    smoothed_trends = [
      SmoothedTrend.new(range_position: 3),
      SmoothedTrend.new(range_position: 4),
      SmoothedTrend.new(range_position: 5, ohlc:)
    ]

    assert_changes 'backtest.reload.current_value', to: 505 do
      BacktestService.call(backtest:, smoothed_trends:)
    end
  end
end
