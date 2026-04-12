# frozen_string_literal: true

require 'test_helper'

class SmoothedTrendSeriveTest < ActiveSupport::TestCase
  test 'returns nothing if insufficient data is available (no SMMAs)' do
    asset_pair = asset_pairs(:atomusd)

    ohlcs = (1..28).map do |i|
      Ohlc.create!(asset_pair:, duration: 1.day, range_position: i, open: 1, high: 1, low: 1, close: 1,
                   volume: 1)
    end

    assert_no_changes 'SmoothedTrend.count' do
      SmoothedTrendService.call(ohlcs)
    end
  end

  test 'turns bullish after 28 consecutive up ticks' do
    asset_pair = asset_pairs(:atomusd)

    ohlcs = (1..28).map do |i|
      Ohlc.create!(asset_pair:, duration: 1.day, range_position: i, open: i, high: i + 1, low: i, close: i + 1,
                   volume: 1)
    end

    ohlcs << bullish_ohlc = Ohlc.create!(asset_pair:, duration: 1.day, range_position: 29, open: 29, high: 30, low: 29,
                                         close: 30, volume: 1)

    # Create SMMAs first
    CreateSmoothedMovingAveragesService.call(ohlcs, SmoothedMovingAverage::INTERVALS)

    SmoothedTrendService.call(ohlcs)

    assert_equal 'bullish', bullish_ohlc.smoothed_trend.trend
  end

  test 'turns bearish after 28 consecutive down ticks' do
    asset_pair = asset_pairs(:atomusd)

    ohlcs = (1..28).map do |i|
      Ohlc.create!(asset_pair:, duration: 1.day, range_position: i, open: 29 - i, high: 29 - i, low: 28 - i,
                   close: 28 - i, volume: 1)
    end

    ohlcs << bearish_ohlc = Ohlc.create!(asset_pair:, duration: 1.day, range_position: 29, open: 1, high: 1, low: 0,
                                         close: 0, volume: 1)

    # Create SMMAs first
    CreateSmoothedMovingAveragesService.call(ohlcs, SmoothedMovingAverage::INTERVALS)

    SmoothedTrendService.call(ohlcs)

    assert_equal 'bearish', bearish_ohlc.smoothed_trend.trend
  end

  test 'turns neutral after 28 consecutive leveled ticks' do
    asset_pair = asset_pairs(:atomusd)

    ohlcs = (1..28).map do |i|
      Ohlc.create!(asset_pair:, duration: 1.day, range_position: i, open: 1, high: 1, low: 1, close: 1,
                   volume: 1)
    end

    ohlcs << neutral_ohlc = Ohlc.create!(asset_pair:, duration: 1.day, range_position: 29, open: 1, high: 1, low: 1,
                                         close: 1, volume: 1)

    # Create SMMAs first
    CreateSmoothedMovingAveragesService.call(ohlcs, SmoothedMovingAverage::INTERVALS)

    SmoothedTrendService.call(ohlcs)

    assert_equal 'neutral', neutral_ohlc.smoothed_trend.trend
  end

  test 'creates trend records in bulk for valid ohlcs with existing SMMAs' do
    asset_pair = asset_pairs(:atomusd)

    ohlcs = (0...29).map do |i|
      Ohlc.create!(asset_pair:, duration: 1.day, range_position: i, open: i, high: i + 1, low: i, close: i + 1,
                   volume: 1)
    end

    # Create SMMAs first (done by CreateSmoothedMovingAveragesService)
    assert_difference 'SmoothedMovingAverage.count' => 4 do
      CreateSmoothedMovingAveragesService.call([ohlcs.last], SmoothedMovingAverage::INTERVALS)
    end

    # Now create trends (only trends, no SMMAs)
    assert_difference 'SmoothedTrend.count' => 1 do
      SmoothedTrendService.call([ohlcs.last])
    end
  end

  test 'flips to bullish to neutral and then to bearish with price action' do
    asset_pair = asset_pairs(:atomusd)

    ohlcs = (0...29).map do |i|
      Ohlc.create!(asset_pair:, duration: 1.day, range_position: i, open: i, high: i + 1, low: i, close: i + 1,
                   volume: 1)
    end

    (0...20).map do |i|
      ohlcs << Ohlc.create!(asset_pair:, duration: 1.day, range_position: i + 29, open: 29 - i, high: 29 - i,
                            low: 28 - i, close: 28 - i, volume: 1)
    end

    ohlcs << bullish_ohlc = Ohlc.create!(asset_pair:, duration: 1.day, range_position: 49, open: 9, high: 9, low: 8,
                                         close: 8, volume: 1)
    ohlcs << neutral_ohlc1 = Ohlc.create!(asset_pair:, duration: 1.day, range_position: 50, open: 8, high: 8, low: 7,
                                          close: 7, volume: 1)
    ohlcs << neutral_ohlc2 = Ohlc.create!(asset_pair:, duration: 1.day, range_position: 51, open: 7, high: 7, low: 6,
                                          close: 6, volume: 1)
    ohlcs << neutral_ohlc3 = Ohlc.create!(asset_pair:, duration: 1.day, range_position: 52, open: 6, high: 6, low: 5,
                                          close: 5, volume: 1)
    ohlcs << bearish_ohlc = Ohlc.create!(asset_pair:, duration: 1.day, range_position: 53, open: 5, high: 5, low: 4,
                                         close: 4, volume: 1)

    # Create SMMAs first
    CreateSmoothedMovingAveragesService.call(ohlcs, SmoothedMovingAverage::INTERVALS)

    SmoothedTrendService.call(ohlcs)

    assert_equal 'bullish', bullish_ohlc.smoothed_trend.trend

    neutral_trend1 = neutral_ohlc1.smoothed_trend
    neutral_trend2 = neutral_ohlc2.smoothed_trend
    neutral_trend3 = neutral_ohlc3.smoothed_trend
    bearish_trend  = bearish_ohlc.smoothed_trend

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
