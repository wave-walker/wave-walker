# frozen_string_literal: true

require 'test_helper'

class OhlcTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test '#previous_ohlcs, returns the previous ohlcs' do
    ohlc = ohlcs(:atom_2019_04_24) # rubocop:disable Naming/VariableNumber

    assert_equal ohlc.previous_ohlcs, [ohlcs(:atom_2019_04_23), ohlcs(:atom_2019_04_22)] # rubocop:disable Naming/VariableNumber
  end

  test '#hl2' do
    assert_equal Ohlc.new(high: 3, low: 2).hl2, 2.5
  end
end
