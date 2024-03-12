# frozen_string_literal: true

require 'test_helper'

class SmoothedTrendSeriveTest < ActiveSupport::TestCase
  test 'it works' do
    assert_nil SmoothedTrendService.call(ohlc: nil)
  end
end
