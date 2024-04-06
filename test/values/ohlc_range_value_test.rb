# frozen_string_literal: true

require 'test_helper'

class OhlcRangeValueTest < ActiveSupport::TestCase
  test '.new, should create range for duration' do
    range = OhlcRangeValue.at(duration: 'PT1H', time: Time.zone.at(0))
    assert_equal Time.zone.at(0), range.begin
    assert_equal Time.zone.at(3600), range.end
  end

  test '.new, should create range at timestamp' do
    range = OhlcRangeValue.at(duration: 'PT4H', time: Time.zone.at(3600 * 4))
    assert_equal Time.zone.at(3600 * 4), range.begin
    assert_equal Time.zone.at(3600 * 8), range.end
  end

  test '.new, should create range for timestamp at any point in range' do
    range = OhlcRangeValue.at(duration: 'PT8H', time: Time.zone.at(3600 * 9))
    assert_equal Time.zone.at(3600 * 8), range.begin
    assert_equal Time.zone.at(3600 * 16), range.end
  end

  test '.new, should create range that dose not include last point' do
    range_h1 = OhlcRangeValue.at(duration: 'PT1H', time: Time.zone.at(0))
    range_h2 = OhlcRangeValue.at(duration: 'PT1H', time: Time.zone.at(3600))

    assert range_h1.cover?(Time.zone.at(3599))
    assert_not range_h1.cover?(Time.zone.at(3600))
    assert range_h2.cover?(Time.zone.at(3600))
  end

  test '#next, should return next range' do
    range_h1 = OhlcRangeValue.at(duration: 'PT1H', time: Time.zone.at(0))
    range_h2 = OhlcRangeValue.at(duration: 'PT1H', time: Time.zone.at(3600))

    assert_equal range_h2, range_h1.next
  end

  test '#position, should return position' do
    assert_equal OhlcRangeValue.at(duration: 'PT1H', time: Time.zone.at(3600)).position, 1
    assert_equal OhlcRangeValue.at(duration: 'PT1H', time: Time.zone.at(7200)).position, 2
    assert_equal OhlcRangeValue.at(duration: 'PT1H', time: Time.zone.at(11_800)).position, 3
  end
end
