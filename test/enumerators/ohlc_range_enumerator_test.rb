# frozen_string_literal: true

require 'test_helper'

class OhlcRangeEnumeratorTest < ActiveSupport::TestCase
  test 'starts with the next new range' do
    asset_pair = asset_pairs(:atomusd)
    duration = 1.day
    asset_pair.imported_until = Time.current

    start_range = OhlcRangeValue.at(duration:, time: 3.days.ago)

    NextNewOhlcRangeValueService.expects(:call).with(asset_pair:, duration:).returns(start_range)

    range, cursor = OhlcRangeEnumerator.call(asset_pair:, duration:).first

    assert_equal range, start_range
    assert_equal cursor, start_range.next.position
  end

  test 'yield the attributes for the first iteration attributes' do
    asset_pair = asset_pairs(:atomusd)
    duration = 1.day
    asset_pair.imported_until = Time.current
    current_range = OhlcRangeValue.at(duration:, time: 1.day.ago)
    cursor = current_range.position

    range, next_cursor = OhlcRangeEnumerator.call(asset_pair:, duration:, cursor:).first

    assert_equal current_range.next.position, next_cursor
    assert_equal range, current_range
  end

  test 'yield the attributes for the next iteration attributes' do
    asset_pair = asset_pairs(:atomusd)
    duration = 1.day
    asset_pair.imported_until = Time.current
    current_range = OhlcRangeValue.at(duration:, time: 2.days.ago)
    cursor = current_range.position

    range, next_next_cursor = OhlcRangeEnumerator.call(asset_pair:, duration:, cursor:).to_a[1]

    assert_equal current_range.next.next.position, next_next_cursor
    assert_equal range, current_range.next
  end

  test 'continues the range when the asset pairs imported_until is not reached' do
    asset_pair = asset_pairs(:atomusd)
    duration = 1.day
    asset_pair.imported_until = Time.current
    cursor = OhlcRangeValue.at(duration:, time: 2.days.ago).position

    iterations = OhlcRangeEnumerator.call(asset_pair:, duration:, cursor:).count

    assert_equal iterations, 2
  end

  test 'stops when the range includes the asset pairs imported until' do
    asset_pair = asset_pairs(:atomusd)
    duration = 1.day
    asset_pair.imported_until = Time.current
    cursor = OhlcRangeValue.at(duration:, time: Time.current).position

    assert_empty OhlcRangeEnumerator.call(asset_pair:, duration:, cursor:).to_a
  end
end
