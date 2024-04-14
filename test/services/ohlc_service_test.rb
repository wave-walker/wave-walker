# frozen_string_literal: true

require 'test_helper'

class OhlcServiceTest < ActiveSupport::TestCase
  setup do
    PartitionService.call(asset_pairs(:atomusd))
  end

  test '.create_from_trades, when no trades exists' do
    asset_pair = asset_pairs(:atomusd)
    duration = 1.hour
    range = OhlcRangeValue.at(duration:, time: Time.current)

    Ohlc.create!(asset_pair:, high: 1, low: 2, open: 3, close: 4, volume: 1,
                 duration:, range_position: range.position)

    ohlc = OhlcService.call(asset_pair:, range: range.next)

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

    ohlc = OhlcService.call(asset_pair:, range:)

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

    assert_nil OhlcService.call(asset_pair:, range:)
  end
end
