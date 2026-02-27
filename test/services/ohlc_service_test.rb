# frozen_string_literal: true

require 'test_helper'

class OhlcServiceTest < ActiveSupport::TestCase
  test '.call, should create a ....' do
    asset_pair = asset_pairs(:atomusd)
    duration = 1.hour

    Trade.create!(id: [asset_pair.id, 1], price: 1, volume: 1, created_at: 3.hours.ago,
                  action: :buy, order_type: :limit, misc: '')
    Trade.create!(id: [asset_pair.id, 2], price: 1, volume: 1, created_at: 2.hours.ago,
                  action: :buy, order_type: :limit, misc: '')
    Trade.create!(id: [asset_pair.id, 3], price: 1, volume: 1, created_at: 1.hour.ago,
                  action: :buy, order_type: :limit, misc: '')

    ranges = [
      OhlcRangeValue.at(duration:, time: 3.hours.ago),
      OhlcRangeValue.at(duration:, time: 2.hours.ago),
      OhlcRangeValue.at(duration:, time: 1.hour.ago)
    ]

    assert_changes 'Ohlc.by_duration(duration).count', to: 3 do
      OhlcService.call(asset_pair:, ranges:)
    end
  end

  # TODO: Consider hl2 for OHLC without trades.
  test '.call, should use the last close to create the OHLC when no trades are in range' do
    asset_pair = asset_pairs(:atomusd)
    duration = 1.hour
    range = OhlcRangeValue.at(duration:, time: Time.current)

    Ohlc.create!(asset_pair:, high: 1, low: 2, open: 3, close: 4, volume: 1,
                 duration:, range_position: range.position)

    OhlcService.call(asset_pair:, ranges: [range.next])

    ohlc = Ohlc.find_by!(asset_pair:, iso8601_duration: duration.iso8601, range_position: range.next.position)

    assert_equal ohlc.high, 4
    assert_equal ohlc.low, 4
    assert_equal ohlc.open, 4
    assert_equal ohlc.close, 4
    assert_equal ohlc.volume, 0
    assert_equal ohlc.duration, 1.hour
    assert_equal ohlc.range_position, range.next.position
  end

  test '.call, should create OHLC with trades in duration' do
    freeze_time

    asset_pair = asset_pairs(:atomusd)
    range = OhlcRangeValue.at(duration: 1.hour, time: 1.hour.ago)

    Trade.create!(id: [asset_pair.id, 1], price: 1, volume: 1, created_at: range.first - 1.second,
                  action: :buy, order_type: :limit, misc: '')

    Trade.create!(id: [asset_pair.id, 2], price: 3, volume: 2, created_at: range.first,
                  action: :buy, order_type: :limit, misc: '')

    Trade.create!(id: [asset_pair.id, 3], price: 2, volume: 3, created_at: range.first + 15.minutes,
                  action: :buy, order_type: :limit, misc: '')

    Trade.create!(id: [asset_pair.id, 4], price: 5, volume: 4, created_at: range.first + 45.minutes,
                  action: :buy, order_type: :limit, misc: '')

    Trade.create!(id: [asset_pair.id, 5], price: 4, volume: 5, created_at: range.end - 1.second,
                  action: :buy, order_type: :limit, misc: '')

    Trade.create!(id: [asset_pair.id, 6], price: 6, volume: 6, created_at: range.end,
                  action: :buy, order_type: :limit, misc: '')

    OhlcService.call(asset_pair:, ranges: [range])

    ohlc = Ohlc.find_by!(asset_pair:, iso8601_duration: 1.hour.iso8601, range_position: range.position)

    assert_equal range, ohlc.range
    assert_equal 1.hour, ohlc.duration
    assert_equal 3, ohlc.open
    assert_equal 5, ohlc.high
    assert_equal 2, ohlc.low
    assert_equal 4, ohlc.close
    assert_equal 14, ohlc.volume
    assert_equal asset_pair, ohlc.asset_pair
  end

  test 'should not create OHLC without trades in duration' do
    asset_pair = asset_pairs(:atomusd)
    range = OhlcRangeValue.at(duration: 1.hour, time: 1.hour.ago)

    assert_no_changes 'Ohlc.by_duration(1.hour).count' do
      OhlcService.call(asset_pair:, ranges: [range])
    end
  end

  test '.call, skips insert when no trades and no previous close' do
    asset_pair = asset_pairs(:atomusd)
    range = OhlcRangeValue.at(duration: 1.hour, time: Time.current)

    assert_no_changes 'Ohlc.by_duration(1.hour).count' do
      OhlcService.call(asset_pair:, ranges: [range])
    end
  end
end
