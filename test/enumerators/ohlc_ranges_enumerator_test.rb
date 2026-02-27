# frozen_string_literal: true

require 'test_helper'

class OhlcRangesEnumeratorTest < ActiveSupport::TestCase
  test 'starts with the next new ranges until last import' do
    asset_pair = asset_pairs(:atomusd)
    duration = 1.day
    asset_pair.imported_until = Time.current

    start_range = OhlcRangeValue.at(duration:, time: 3.days.ago)

    NextNewOhlcRangeValueService.expects(:call).with(asset_pair:, duration:).returns(start_range)

    ranges, cursor = OhlcRangesEnumerator.call(asset_pair:, duration:).first

    assert_equal ranges, [start_range, start_range.next, start_range.next.next]
    assert_equal cursor, start_range.position + ranges.size
  end

  test 'yield the ranges for the first iteration attributes' do
    asset_pair = asset_pairs(:atomusd)
    duration = 1.day
    asset_pair.imported_until = Time.current
    current_range = OhlcRangeValue.at(duration:, time: 1.day.ago)
    cursor = current_range.position

    ranges, next_cursor = OhlcRangesEnumerator.call(asset_pair:, duration:, cursor:).first

    assert_equal ranges, [current_range]
    assert_equal current_range.next.position, next_cursor
  end

  test 'yield the ranges for the next iteration attributes' do
    asset_pair = asset_pairs(:atomusd)
    duration = 1.day
    asset_pair.imported_until = Time.current
    start_range = OhlcRangeValue.at(duration:, time: 101.days.ago)
    next_iteration_range = OhlcRangeValue.at(duration:, time: 1.day.ago)

    ranges, cursor = OhlcRangesEnumerator.call(
      asset_pair:,
      duration:,
      cursor: start_range.position
    ).to_a[1]

    assert_equal ranges, [next_iteration_range]
    assert_equal cursor, next_iteration_range.next.position
  end

  test 'stops when the range includes the asset pairs imported until' do
    asset_pair = asset_pairs(:atomusd)
    duration = 1.day
    asset_pair.imported_until = Time.current
    cursor = OhlcRangeValue.at(duration:, time: Time.current).position

    assert_empty OhlcRangesEnumerator.call(asset_pair:, duration:, cursor:).to_a
  end
end
