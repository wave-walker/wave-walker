# frozen_string_literal: true

require 'test_helper'

class OhlcRangeTest < ActiveSupport::TestCase
  test '.next_new_range, when there are no OHLCs' do
    asset_pair = asset_pairs(:atomusd)
    timeframe = :PT1H
    timestamp = 4.hours.ago
    PartitionService.call(asset_pair)

    Trade.create!(
      id: [asset_pair.id, 1],
      price: 1,
      volume: 1,
      action: :buy,
      order_type: :market,
      misc: '',
      created_at: timestamp
    )

    expected_range = Ohlc::Range.new(timeframe, timestamp)

    assert_equal expected_range, Ohlc::Range.next_new_range(asset_pair:, timeframe:)
  end

  test '.next_new_range, when there are previous OHLCs' do
    asset_pair = asset_pairs(:atomusd)
    timeframe = :PT1H

    ohlc_range = Ohlc::Range.new(timeframe, 3.hours.ago)

    Ohlc.create!(asset_pair:, start_at: ohlc_range.begin, timeframe:,
                 open: 1, high: 1, low: 1, close: 1, volume: 1)
    expected_range = Ohlc::Range.new(timeframe, 2.hours.ago)

    assert_equal expected_range, Ohlc::Range.next_new_range(asset_pair:, timeframe:)
  end

  test '.new, should create range for timeframe' do
    range = Ohlc::Range.new('PT1H', Time.zone.at(0))
    assert_equal Time.zone.at(0), range.begin
    assert_equal Time.zone.at(3600), range.end
  end

  test '.new, should create range at timestamp' do
    range = Ohlc::Range.new('PT4H', Time.zone.at(3600 * 4))
    assert_equal Time.zone.at(3600 * 4), range.begin
    assert_equal Time.zone.at(3600 * 8), range.end
  end

  test '.new, should create range for timestamp at any point in range' do
    range = Ohlc::Range.new('PT8H', Time.zone.at(3600 * 9))
    assert_equal Time.zone.at(3600 * 8), range.begin
    assert_equal Time.zone.at(3600 * 16), range.end
  end

  test '.new, should create range that dose not include last point' do
    range_h1 = Ohlc::Range.new('PT1H', Time.zone.at(0))
    range_h2 = Ohlc::Range.new('PT1H', Time.zone.at(3600))

    assert range_h1.cover?(Time.zone.at(3599))
    assert_not range_h1.cover?(Time.zone.at(3600))
    assert range_h2.cover?(Time.zone.at(3600))
  end

  test '#next, should return next range' do
    range_h1 = Ohlc::Range.new('PT1H', Time.zone.at(0))
    range_h2 = Ohlc::Range.new('PT1H', Time.zone.at(3600))

    assert_equal range_h2, range_h1.next
  end
end
