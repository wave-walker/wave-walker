# frozen_string_literal: true

require 'test_helper'

class NextNewOhlcRangeValueServiceTest < ActiveSupport::TestCase
  test '.call, returns OhlcRangeValue at first trade when no OHLCs are present' do
    asset_pair = asset_pairs(:atomusd)
    duration = 'PT1H'
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

    expected_range = OhlcRangeValue.at(time: timestamp, duration:)

    assert_equal expected_range, NextNewOhlcRangeValueService.call(asset_pair:, duration:)
  end

  test '.call, returns the next OhlcRangeValue when OHLCs are present' do
    asset_pair = asset_pairs(:atomusd)
    duration = 'PT1H'

    ohlc_range = OhlcRangeValue.at(time: 3.hours.ago, duration:)

    Ohlc.create!(asset_pair:, range_position: ohlc_range.position, duration:,
                 open: 1, high: 1, low: 1, close: 1, volume: 1)
    expected_range = OhlcRangeValue.at(time: 2.hours.ago, duration:)

    assert_equal expected_range, NextNewOhlcRangeValueService.call(asset_pair:, duration:)
  end
end
