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
end
