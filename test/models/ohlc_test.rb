# frozen_string_literal: true

require 'test_helper'

class OhlcTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test '#previous_ohlcs, returns the previous ohlcs' do
    ohlc = ohlcs(:atom20221203)

    assert_equal ohlc.previous_ohlcs, [ohlcs(:atom20221202), ohlcs(:atom20221201)]
  end

  test '#hl2' do
    assert_equal Ohlc.new(high: 3, low: 2).hl2, 2.5
  end

  test '.with_complete_smmas, returns only OHLCs with all required SMMA intervals' do
    asset_pair = asset_pairs(:atomusd)
    test_intervals = [10, 20] # Test with just 2 intervals

    # Create OHLCs
    ohlc_complete = Ohlc.create!(
      asset_pair: asset_pair,
      duration: 1.day,
      range_position: 100_000,
      open: 10.0, high: 11.0, low: 9.0, close: 10.0, volume: 1000
    )

    ohlc_incomplete = Ohlc.create!(
      asset_pair: asset_pair,
      duration: 1.day,
      range_position: 100_001,
      open: 10.0, high: 11.0, low: 9.0, close: 10.0, volume: 1000
    )

    # Create both test SMMAs for first OHLC
    test_intervals.each do |interval|
      SmoothedMovingAverage.create!(
        asset_pair_id: asset_pair.id,
        iso8601_duration: 'P1D',
        range_position: 100_000,
        interval: interval,
        value: 10.0
      )
    end

    # Create only 1 SMMA for second OHLC (incomplete)
    SmoothedMovingAverage.create!(
      asset_pair_id: asset_pair.id,
      iso8601_duration: 'P1D',
      range_position: 100_001,
      interval: 10,
      value: 10.0
    )

    result = Ohlc.where(asset_pair: asset_pair).by_duration(1.day).with_complete_smmas(test_intervals)

    assert_includes result, ohlc_complete
    assert_not_includes result, ohlc_incomplete
  end

  test '.without_smoothed_trend, returns only OHLCs without a trend' do
    asset_pair = asset_pairs(:atomusd)

    ohlc_with_trend = Ohlc.create!(
      asset_pair: asset_pair,
      duration: 1.day,
      range_position: 200_000,
      open: 10.0, high: 11.0, low: 9.0, close: 10.0, volume: 1000
    )

    ohlc_without_trend = Ohlc.create!(
      asset_pair: asset_pair,
      duration: 1.day,
      range_position: 200_001,
      open: 10.0, high: 11.0, low: 9.0, close: 10.0, volume: 1000
    )

    # Create trend for first OHLC
    SmoothedTrend.create!(
      asset_pair_id: asset_pair.id,
      iso8601_duration: 'P1D',
      range_position: 200_000,
      fast_smma: 10.0,
      slow_smma: 10.0,
      trend: :neutral,
      flip: false
    )

    result = Ohlc.where(asset_pair: asset_pair).by_duration(1.day).without_smoothed_trend

    assert_not_includes result, ohlc_with_trend
    assert_includes result, ohlc_without_trend
  end
end
