# frozen_string_literal: true

require 'test_helper'

class OhlcRangeEnumeratorTest < ActiveSupport::TestCase
  test 'starts with the next new range' do
    asset_pair = asset_pairs(:atomusd)
    timeframe = 'P1D'
    last_imported_at = Time.current

    start_range = Ohlc::Range.new(timeframe, 3.days.ago)

    Ohlc::Range.expects(:next_new_range).with(asset_pair:, timeframe:).returns(start_range)

    range, cursor = OhlcRangeEnumerator.call(asset_pair:, timeframe:, last_imported_at:).first

    assert_equal range, start_range
    assert_equal cursor, start_range.next
  end

  test 'yield the attributes for the first iteration attributes' do
    asset_pair = asset_pairs(:atomusd)
    timeframe = 'P1D'
    last_imported_at = Time.current
    cursor = Ohlc::Range.new(timeframe, 1.day.ago)

    range, next_cursor = OhlcRangeEnumerator.call(asset_pair:, timeframe:, last_imported_at:, cursor:).first

    assert_equal cursor.next, next_cursor
    assert_equal range, cursor
  end

  test 'yield the attributes for the next iteration attributes' do
    asset_pair = asset_pairs(:atomusd)
    timeframe = 'P1D'
    last_imported_at = Time.current
    cursor = Ohlc::Range.new(timeframe, 2.days.ago)

    range, next_next_cursor = OhlcRangeEnumerator.call(asset_pair:, timeframe:, last_imported_at:, cursor:).to_a[1]

    assert_equal cursor.next.next, next_next_cursor
    assert_equal range, cursor.next
  end

  test 'continues the range when last_imported_at is not reached' do
    asset_pair = asset_pairs(:atomusd)
    timeframe = 'P1D'
    last_imported_at = Time.current
    cursor = Ohlc::Range.new(timeframe, 2.days.ago)

    iterations = OhlcRangeEnumerator.call(asset_pair:, timeframe:, last_imported_at:, cursor:).count

    assert_equal iterations, 2
  end

  test 'stops when the range includes last_imported_at' do
    asset_pair = asset_pairs(:atomusd)
    timeframe = 'P1D'
    last_imported_at = Time.current
    cursor = Ohlc::Range.new(timeframe, Time.current)

    assert_empty OhlcRangeEnumerator.call(asset_pair:, timeframe:, last_imported_at:, cursor:).to_a
  end
end
