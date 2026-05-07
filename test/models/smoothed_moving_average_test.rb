# frozen_string_literal: true

require 'test_helper'

class SmoothedMovingAverageTest < ActiveSupport::TestCase
  test '.latest_range_position returns the maximum range_position for given asset_pair and duration' do
    asset_pair = asset_pairs(:atomusd)
    duration = 1.day

    result = SmoothedMovingAverage.latest_range_position(asset_pair: asset_pair, duration: duration)

    assert_equal 19_329, result
  end

  test '.latest_range_position returns nil when no records exist for asset_pair and duration' do
    asset_pair = asset_pairs(:btcusd)
    duration = 1.week

    result = SmoothedMovingAverage.latest_range_position(asset_pair: asset_pair, duration: duration)

    assert_nil result
  end

  test '.latest_range_position filters by duration correctly' do
    asset_pair = asset_pairs(:atomusd)
    duration = 2.days

    result = SmoothedMovingAverage.latest_range_position(asset_pair: asset_pair, duration: duration)

    assert_equal 5000, result
  end

  test '.create_initial_sma returns nil when not enough OHLCs exist' do
    asset_pair = asset_pairs(:atomusd)
    duration = 2.days
    interval = 3

    result = SmoothedMovingAverage.create_initial_sma(asset_pair: asset_pair, duration: duration, interval: interval)

    assert_nil result
  end

  test '.create_initial_sma calculates correct SMA value' do
    asset_pair = asset_pairs(:atomusd)
    duration = 1.day
    interval = 5

    result = SmoothedMovingAverage.create_initial_sma(asset_pair: asset_pair, duration: duration, interval: interval)

    # Expected calculation:
    # OHLCs from range_position 19327 to 19331 (5 OHLCs)
    # atom20221201: hl2 = (10.5699 + 10.1432) / 2 = 10.35655
    # atom20221202: hl2 = (10.3772 + 10.1234) / 2 = 10.2503
    # atom20221203: hl2 = (10.4088 + 9.9905) / 2 = 10.19965
    # atom20221204: hl2 = (10.2816 + 10.033) / 2 = 10.1573
    # atom20221205: hl2 = (10.5662 + 10.1322) / 2 = 10.3492
    # SMA = (10.35655 + 10.2503 + 10.19965 + 10.1573 + 10.3492) / 5 = 10.2626
    expected_sma = 10.2626
    assert_in_delta expected_sma, result.value, 0.0001
  end

  test '.create_initial_sma rounds to asset pair cost_decimals' do
    asset_pair = asset_pairs(:atomusd)
    asset_pair.update!(cost_decimals: 2)
    duration = 1.day
    interval = 5

    result = SmoothedMovingAverage.create_initial_sma(asset_pair: asset_pair, duration: duration, interval: interval)

    assert_equal 2, result.value.to_s.split('.').last.length
  end
end
