require 'test_helper'

class Ohlc::RangeTest < ActiveSupport::TestCase
  test ".new, should create range for timeframe" do
    range = Ohlc::Range.new("PT1H", Time.zone.at(0))
    assert_equal Time.zone.at(0), range.begin
    assert_equal Time.zone.at(3600), range.end
  end

  test ".new, should create range at timestamp" do
    range = Ohlc::Range.new("PT4H", Time.zone.at(3600 * 4))
    assert_equal Time.zone.at(3600 * 4), range.begin
    assert_equal Time.zone.at(3600 * 8), range.end
  end

  test ".new, should create range for timestamp at any point in range" do
    range = Ohlc::Range.new("PT8H", Time.zone.at(3600 * 9))
    assert_equal Time.zone.at(3600 * 8), range.begin
    assert_equal Time.zone.at(3600 * 16), range.end
  end

  test ".new, should create range that dose not include last point" do
    range_h1 = Ohlc::Range.new("PT1H", Time.zone.at(0))
    range_h2 = Ohlc::Range.new("PT1H", Time.zone.at(3600))

    assert range_h1.cover?(Time.zone.at(3599))
    assert_not range_h1.cover?(Time.zone.at(3600))
    assert range_h2.cover?(Time.zone.at(3600))
  end

  test "#next, should return next range" do
    range_h1 = Ohlc::Range.new("PT1H", Time.zone.at(0))
    range_h2 = Ohlc::Range.new("PT1H", Time.zone.at(3600))

    assert_equal range_h2, range_h1.next
  end
end
