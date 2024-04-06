# frozen_string_literal: true

require 'test_helper'

class SmoothedTrendSeriveTest < ActiveSupport::TestCase
  test 'returns nothing when not enough OHLCs are present' do
    assert_nil SmoothedTrendService.call(ohlcs(:atom_2019_05_15)) # rubocop:disable Naming/VariableNumber
  end

  test 'creates a SmoothedTrend when enough OHLCs are present' do
    assert SmoothedTrendService.call(ohlcs(:atom_2019_05_25)) # rubocop:disable Naming/VariableNumber
  end
end
