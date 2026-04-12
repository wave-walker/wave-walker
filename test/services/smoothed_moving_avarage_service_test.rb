# frozen_string_literal: true

require 'test_helper'

class SmoothedMovingAverageServiceTest < ActiveSupport::TestCase
  test '#call, returns nil for insufficient OHLCs' do
    assert_nil SmoothedMovingAverageService.call(ohlc: ohlcs(:atom20221205), interval: 5)
  end

  test '#call, returns attributes hash for the first smoothed moving average' do
    ohlc = ohlcs(:atom20221206)

    attrs = SmoothedMovingAverageService.call(ohlc:, interval: 5)

    assert_kind_of Hash, attrs
    assert_in_delta attrs[:value], 10.2626, 0.00001
    assert_equal ohlc.asset_pair_id, attrs[:asset_pair_id]
    assert_equal ohlc.iso8601_duration, attrs[:iso8601_duration]
    assert_equal ohlc.range_position, attrs[:range_position]
    assert_equal 5, attrs[:interval]
  end

  test '#call, does not persist records' do
    ohlc = ohlcs(:atom20221206)

    assert_no_changes 'SmoothedMovingAverage.count' do
      SmoothedMovingAverageService.call(ohlc:, interval: 5)
    end
  end

  test '#call, calculates SMMA with smma_cache for previous value' do
    smma_cache = {}

    SmoothedMovingAverageService.call(ohlc: ohlcs(:atom20221206), interval: 5, smma_cache:)
    result = SmoothedMovingAverageService.call(ohlc: ohlcs(:atom20221207), interval: 5, smma_cache:)

    assert_in_delta result[:value], 10.17848, 0.00001
  end

  test '#call, rounds the values to the asset pairs cost decimals' do
    ohlc = ohlcs(:atom20230108)
    ohlc.asset_pair.update!(cost_decimals: 2)

    attrs = SmoothedMovingAverageService.call(ohlc:, interval: 5)

    assert_equal 10.15, attrs[:value]
  end
end