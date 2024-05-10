# frozen_string_literal: true

require 'test_helper'

class BacktestTest < ActiveSupport::TestCase
  test 'smoothed_trends, should retrun associated smoothed_trends' do
    smoothed_trends = [
      SmoothedTrendService.call(ohlcs(:atom20230101)),
      SmoothedTrendService.call(ohlcs(:atom20230102)),
      SmoothedTrendService.call(ohlcs(:atom20230103))
    ]

    backtest = backtests(:atom)

    assert_equal smoothed_trends, backtest.smoothed_trends
  end

  test 'backtest_results, should not retrun unrelated smoothed_trends' do
    asset_pair = asset_pairs(:atomusd)

    ohlc_h1 = Ohlc.create!(
      asset_pair:, duration: 1.hour, range_position: 1,
      open: 1, high: 1, low: 1, close: 1, volume: 1
    )

    btc_ohlc = Ohlc.create!(
      asset_pair: asset_pairs(:btcusd), duration: 1.day,
      range_position: 1, open: 1, high: 1, low: 1, close: 1, volume: 1
    )

    SmoothedTrendService.call(ohlc_h1)
    SmoothedTrendService.call(btc_ohlc)

    backtest = backtests(:atom)

    assert_empty backtest.smoothed_trends
  end

  test 'new_smoothed_trends, should return untested smoothed_trends' do
    backtested_trend = SmoothedTrendService.call(ohlcs(:atom20230101))

    smoothed_trends = [
      SmoothedTrendService.call(ohlcs(:atom20230102)),
      SmoothedTrendService.call(ohlcs(:atom20230103))
    ]

    backtest = backtests(:atom)
    backtest.update(last_range_position: backtested_trend.range_position)

    assert_equal smoothed_trends, backtest.new_smoothed_trends
  end

  test '#usd_quantitiy, sets backtest funds to 10.000$' do
    backtest = Backtest.create!(asset_pair: asset_pairs(:btcusd), duration: 1.day)

    assert_equal backtest.usd_quantity, 10_000
  end
end
