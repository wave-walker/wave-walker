# frozen_string_literal: true

require 'test_helper'

class SmoothedMovingAverageServiceTest < ActiveSupport::TestCase
  test '#create, dose not create for insufficient OHLCs' do
    assert_nil SmoothedMovingAverageService.call(ohlc: ohlcs(:atom_2019_04_26), interval: 5) # rubocop:disable Naming/VariableNumber
    smma = SmoothedMovingAverageService.call(ohlc: ohlcs(:atom_2019_04_27), interval: 5) # rubocop:disable Naming/VariableNumber

    assert_kind_of SmoothedMovingAverage, smma
  end

  test '#create, returns the correct first smoothed moving average' do
    ohlc = ohlcs(:atom_2019_04_27) # rubocop:disable Naming/VariableNumber

    smma = SmoothedMovingAverageService.call(ohlc:, interval: 5)

    assert_in_delta smma.value, 4.17149, 0.00001
  end

  test '#create, calculates SMMA with previous SMMA' do
    SmoothedMovingAverageService.call(ohlc: ohlcs(:atom_2019_04_27), interval: 5) # rubocop:disable Naming/VariableNumber
    smma = SmoothedMovingAverageService.call(ohlc: ohlcs(:atom_2019_04_28), interval: 5) # rubocop:disable Naming/VariableNumber

    assert_in_delta smma.value, 4.16778, 0.00001
  end
end
