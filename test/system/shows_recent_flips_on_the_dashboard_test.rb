# frozen_string_literal: true

require 'application_system_test_case'

class ShowRecentFlipsOnTheDashboardTest < ApplicationSystemTestCase
  test 'show recent daily flips on the dashboard' do
    travel_to Time.zone.local(2024, 1, 9)

    atom_usd = asset_pairs(:atomusd)
    btc_usd = asset_pairs(:btcusd)
    duration = 1.day
    position = OhlcRangeValue.at(duration:, time: 1.week.ago).position

    Ohlc.create!(asset_pair: atom_usd, duration:, range_position: position - 1, open: 1, high: 1, low: 1, close: 1,
                 volume: 1)
    Ohlc.create!(asset_pair: btc_usd, duration:, range_position: position, open: 1, high: 1, low: 1, close: 1,
                 volume: 1)
    Ohlc.create!(asset_pair: atom_usd, duration:, range_position: position + 1, open: 1, high: 1, low: 1, close: 1,
                 volume: 1)

    SmoothedTrend.create!(asset_pair: atom_usd, duration:, range_position: position - 1, flip: true, trend: 'neutral',
                          slow_smma: 1, fast_smma: 2)
    SmoothedTrend.create!(asset_pair: btc_usd, duration:, range_position: position, flip: true, trend: 'bullish',
                          slow_smma: 1, fast_smma: 2)
    SmoothedTrend.create!(asset_pair: atom_usd, duration:, range_position: position + 1, flip: true, trend: 'bearish',
                          slow_smma: 1, fast_smma: 2)

    visit '/'

    within '#recent-flips' do
      assert_no_text '2023-01-01 ATOMUSD flipped to neutral'
      assert_text '2024-01-02 BTCUSD flipped to bullish'
      assert_text '2024-01-03 ATOMUSD flipped to bearish'
    end
  end
end
