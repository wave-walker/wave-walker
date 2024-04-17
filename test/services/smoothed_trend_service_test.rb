# frozen_string_literal: true

require 'test_helper'

class SmoothedTrendSeriveTest < ActiveSupport::TestCase
  test 'returns nothing if insufficent data is avalible' do
    asset_pair = asset_pairs(:atomusd)

    28.times do |i|
      ohlc = Ohlc.create!(asset_pair:, duration: 1.day, range_position: i, open: 1, high: 1, low: 1, close: 1,
                          volume: 1)

      assert_nil SmoothedTrendService.call(ohlc)
    end
  end

  test 'turns bullish after 28 consecutive up ticks' do
    asset_pair = asset_pairs(:atomusd)

    28.times do |i|
      ohlc = Ohlc.create!(asset_pair:, duration: 1.day, range_position: i, open: i, high: i + 1, low: i, close: i + 1,
                          volume: 1)
      SmoothedTrendService.call(ohlc)
    end

    ohlc = Ohlc.create!(asset_pair:, duration: 1.day, range_position: 29, open: 29, high: 30, low: 29, close: 30,
                        volume: 1)

    assert_equal 'bullish', SmoothedTrendService.call(ohlc).trend
  end

  test 'turns bearish after 28 consecutive down ticks' do
    asset_pair = asset_pairs(:atomusd)

    28.times do |i|
      ohlc = Ohlc.create!(asset_pair:, duration: 1.day, range_position: i, open: 29 - i, high: 29 - i, low: 28 - i,
                          close: 28 - i, volume: 1)
      SmoothedTrendService.call(ohlc)
    end

    ohlc = Ohlc.create!(asset_pair:, duration: 1.day, range_position: 29, open: 1, high: 1, low: 0, close: 0, volume: 1)

    assert_equal 'bearish', SmoothedTrendService.call(ohlc).trend
  end

  test 'turns neutral after 28 consecutive leveled ticks' do
    asset_pair = asset_pairs(:atomusd)

    28.times do |i|
      ohlc = Ohlc.create!(asset_pair:, duration: 1.day, range_position: i, open: 1, high: 1, low: 1, close: 1,
                          volume: 1)
      SmoothedTrendService.call(ohlc)
    end

    ohlc = Ohlc.create!(asset_pair:, duration: 1.day, range_position: 29, open: 1, high: 1, low: 1, close: 1, volume: 1)

    assert_equal 'neutral', SmoothedTrendService.call(ohlc).trend
  end

  test 'flips to bullish to neutral and then to bearish with price action' do # rubocop:disable Metrics/BlockLength
    asset_pair = asset_pairs(:atomusd)

    29.times do |i|
      ohlc = Ohlc.create!(asset_pair:, duration: 1.day, range_position: i, open: i, high: i + 1, low: i, close: i + 1,
                          volume: 1)
      SmoothedTrendService.call(ohlc)
    end

    20.times do |i|
      ohlc = Ohlc.create!(asset_pair:, duration: 1.day, range_position: i + 29, open: 29 - i, high: 29 - i,
                          low: 28 - i, close: 28 - i, volume: 1)
      SmoothedTrendService.call(ohlc)
    end

    bullish_ohlc = Ohlc.create!(asset_pair:, duration: 1.day, range_position: 49, open: 9, high: 9, low: 8, close: 8,
                                volume: 1)
    neutral_ohlc1 = Ohlc.create!(asset_pair:, duration: 1.day, range_position: 50, open: 8, high: 8, low: 7, close: 7,
                                 volume: 1)
    neutral_ohlc2 = Ohlc.create!(asset_pair:, duration: 1.day, range_position: 51, open: 7, high: 7, low: 6, close: 6,
                                 volume: 1)
    neutral_ohlc3 = Ohlc.create!(asset_pair:, duration: 1.day, range_position: 52, open: 6, high: 6, low: 5, close: 5,
                                 volume: 1)
    bearish_ohlc = Ohlc.create!(asset_pair:, duration: 1.day, range_position: 53, open: 5, high: 5, low: 4, close: 4,
                                volume: 1)

    assert_equal 'bullish', SmoothedTrendService.call(bullish_ohlc).trend

    neutral_trend1 = SmoothedTrendService.call(neutral_ohlc1)
    neutral_trend2 = SmoothedTrendService.call(neutral_ohlc2)
    neutral_trend3 = SmoothedTrendService.call(neutral_ohlc3)
    bearish_trend = SmoothedTrendService.call(bearish_ohlc)

    assert_equal 'neutral', neutral_trend1.trend
    assert neutral_trend1.flip?
    assert_equal 'neutral', neutral_trend2.trend
    assert_not neutral_trend2.flip?
    assert_equal 'neutral', neutral_trend3.trend
    assert_not neutral_trend3.flip?
    assert_equal 'bearish', bearish_trend.trend
    assert bearish_trend.flip?
  end
end
