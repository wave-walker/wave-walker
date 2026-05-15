# frozen_string_literal: true

require 'test_helper'

class BacktestTest < ActiveSupport::TestCase
  test 'smoothed_trends, should retrun associated smoothed_trends' do
    ohlcs = [ohlcs(:atom20230101), ohlcs(:atom20230102), ohlcs(:atom20230103)]

    ohlcs.each do |ohlc|
      SmoothedTrend.create!(
        asset_pair: ohlc.asset_pair, iso8601_duration: ohlc.iso8601_duration, range_position: ohlc.range_position,
        fast_smma: 1.0, slow_smma: 1.0, trend: :bullish, flip: false
      )
    end

    backtest = backtests(:atom)

    assert_equal ohlcs.map(&:smoothed_trend), backtest.smoothed_trends
  end

  test 'backtest_results, should not retrun unrelated smoothed_trends' do
    asset_pair = asset_pairs(:atomusd)

    Ohlc.create!(
      asset_pair:, duration: 1.hour, range_position: 1,
      open: 1, high: 1, low: 1, close: 1, volume: 1
    )

    Ohlc.create!(
      asset_pair: asset_pairs(:btcusd), duration: 1.day,
      range_position: 1, open: 1, high: 1, low: 1, close: 1, volume: 1
    )

    backtest = backtests(:atom)

    assert_empty backtest.smoothed_trends
  end

  test 'new_smoothed_trends, should return untested smoothed_trends' do
    backtested_trend = SmoothedTrend.create!(
      asset_pair: ohlcs(:atom20230101).asset_pair,
      iso8601_duration: ohlcs(:atom20230101).iso8601_duration,
      range_position: ohlcs(:atom20230101).range_position,
      fast_smma: 1.0, slow_smma: 1.0, trend: :bullish, flip: false
    )

    ohlcs = [ohlcs(:atom20230102), ohlcs(:atom20230103)]
    ohlcs.each do |ohlc|
      SmoothedTrend.create!(
        asset_pair: ohlc.asset_pair, iso8601_duration: ohlc.iso8601_duration, range_position: ohlc.range_position,
        fast_smma: 1.0, slow_smma: 1.0, trend: :bullish, flip: false
      )
    end

    backtest = backtests(:atom)
    backtest.update(last_range_position: backtested_trend.range_position)

    assert_equal ohlcs.map(&:smoothed_trend), backtest.new_smoothed_trends
  end

  test '#usd_quantitiy, sets backtest funds to 10.000$ on creation' do
    backtest = Backtest.create!(asset_pair: asset_pairs(:btcusd), duration: 1.day)

    assert_equal backtest.usd_volume, 10_000
  end

  test '#current_value, sets current value to the usd volume on creation' do
    backtest = Backtest.create!(asset_pair: asset_pairs(:btcusd), duration: 1.day)

    assert_equal backtest.current_value, backtest.usd_volume
  end

  test '#percentage_change, should return the percentage change of the current value' do
    backtest = backtests(:atom)

    assert_equal backtest.percentage_change, 0

    backtest.update(current_value: 12_345)

    assert_equal backtest.percentage_change, 23.45

    backtest.update(current_value: 9876)

    assert_equal backtest.percentage_change, -1.24
  end
end
