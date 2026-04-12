# frozen_string_literal: true

require 'test_helper'

class BacktestTest < ActiveSupport::TestCase
  test 'smoothed_trends, should retrun associated smoothed_trends' do
    ohlcs_list = [ohlcs(:atom20230101), ohlcs(:atom20230102), ohlcs(:atom20230103)]

    # Create SMMAs first, then trends
    CreateSmoothedMovingAveragesService.call(ohlcs_list, SmoothedMovingAverage::INTERVALS)
    SmoothedTrendService.call(ohlcs_list)

    backtest = backtests(:atom)

    assert_equal ohlcs_list.map(&:smoothed_trend), backtest.smoothed_trends
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

    # These OHLCs don't have enough prior data for SMMAs, so no trends will be created
    CreateSmoothedMovingAveragesService.call([ohlc_h1, btc_ohlc], SmoothedMovingAverage::INTERVALS)
    SmoothedTrendService.call([ohlc_h1, btc_ohlc])

    backtest = backtests(:atom)

    assert_empty backtest.smoothed_trends
  end

  test 'new_smoothed_trends, should return untested smoothed_trends' do
    ohlc_01 = ohlcs(:atom20230101)
    ohlc_02 = ohlcs(:atom20230102)
    ohlc_03 = ohlcs(:atom20230103)

    # Create SMMAs first, then trends
    CreateSmoothedMovingAveragesService.call([ohlc_01], SmoothedMovingAverage::INTERVALS)
    SmoothedTrendService.call([ohlc_01])
    backtested_trend = ohlc_01.smoothed_trend

    ohlcs_list = [ohlc_02, ohlc_03]
    CreateSmoothedMovingAveragesService.call(ohlcs_list, SmoothedMovingAverage::INTERVALS)
    SmoothedTrendService.call(ohlcs_list)

    backtest = backtests(:atom)
    backtest.update(last_range_position: backtested_trend.range_position)

    assert_equal ohlcs_list.map(&:smoothed_trend), backtest.new_smoothed_trends
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
