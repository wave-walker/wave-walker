# frozen_string_literal: true

require 'test_helper'

class SmoothedTrendSeriveTest < ActiveSupport::TestCase
  test 'returns nothing when not enough OHLCs are present' do
    assert_nil SmoothedTrendService.call(ohlc: ohlcs(:atom_2019_04_26)) # rubocop:disable Naming/VariableNumber
  end
end
