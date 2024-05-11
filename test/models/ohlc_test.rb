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
end
