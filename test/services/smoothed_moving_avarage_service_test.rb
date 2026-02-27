# frozen_string_literal: true

require 'test_helper'

class SmoothedMovingAverageServiceTest < ActiveSupport::TestCase
  test '#create, dose not create for insufficient OHLCs' do
    assert_nil SmoothedMovingAverageService.call(ohlc: ohlcs(:atom20221205), interval: 5)
    smma = SmoothedMovingAverageService.call(ohlc: ohlcs(:atom20221206), interval: 5)

    assert_kind_of SmoothedMovingAverage, smma
  end

  test '#create, returns the correct first smoothed moving average' do
    ohlc = ohlcs(:atom20221206)

    smma = SmoothedMovingAverageService.call(ohlc:, interval: 5)

    assert_in_delta smma.value, 10.2626, 0.00001
  end

  test '#create, calculates SMMA with previous SMMA' do
    SmoothedMovingAverageService.call(ohlc: ohlcs(:atom20221206), interval: 5)
    smma = SmoothedMovingAverageService.call(ohlc: ohlcs(:atom20221207), interval: 5)

    assert_in_delta smma.value, 10.17848, 0.00001
  end

  test '#create, rounds the values to the asset pairs cost decimals' do
    ohlc = ohlcs(:atom20230108)
    ohlc.asset_pair.update!(cost_decimals: 2)

    smma = SmoothedMovingAverageService.call(ohlc:, interval: 5)

    assert_equal smma.value, 10.15
  end

  test '#create, persists with composite key columns' do
    ohlc = ohlcs(:atom20221206)

    SmoothedMovingAverageService.call(ohlc:, interval: 5)

    smma = SmoothedMovingAverage.find_by!(
      asset_pair_id: ohlc.asset_pair_id,
      iso8601_duration: ohlc.iso8601_duration,
      range_position: ohlc.range_position,
      interval: 5
    )

    assert_equal smma.asset_pair_id, ohlc.asset_pair_id
    assert_equal smma.iso8601_duration, ohlc.iso8601_duration
    assert_equal smma.range_position, ohlc.range_position
    assert_equal smma.interval, 5
  end
end
