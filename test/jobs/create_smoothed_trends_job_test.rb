# frozen_string_literal: true

require 'test_helper'

class CreateSmoothedTrendsJobTest < ActiveJob::TestCase
  test '#perform, creates smoothed trends for ohlcs without one' do
    asset_pair = AssetPair.create!(
      base: 'TST',
      quote: 'ZUSD',
      name: 'TSTUSD',
      name_on_exchange: 'TSTUSD',
      cost_decimals: 2,
      importing: false
    )
    ohlc_with_trend = Ohlc.create!(
      asset_pair:,
      duration: 1.day,
      range_position: 1,
      open: 1,
      high: 1,
      low: 1,
      close: 1,
      volume: 1
    )
    ohlc_without_trend = Ohlc.create!(
      asset_pair:,
      duration: 1.day,
      range_position: 2,
      open: 1,
      high: 1,
      low: 1,
      close: 1,
      volume: 1
    )

    SmoothedTrend.create!(
      asset_pair:,
      ohlc: ohlc_with_trend,
      duration: ohlc_with_trend.duration,
      range_position: ohlc_with_trend.range_position,
      fast_smma: 1,
      slow_smma: 1,
      trend: :neutral,
      flip: false
    )

    SmoothedTrendService.expects(:call).with(ohlc_without_trend).once
    SmoothedTrendService.expects(:call).with(ohlc_with_trend).never

    CreateSmoothedTrendsJob.perform_now(asset_pair:, duration: ohlc_with_trend.duration)
  end

  test '#perform, skips ohlcs that already have a trend' do
    asset_pair = AssetPair.create!(
      base: 'TST',
      quote: 'ZUSD',
      name: 'TST2USD',
      name_on_exchange: 'TST2USD',
      cost_decimals: 2,
      importing: false
    )
    ohlc = Ohlc.create!(
      asset_pair:,
      duration: 1.day,
      range_position: 1,
      open: 1,
      high: 1,
      low: 1,
      close: 1,
      volume: 1
    )

    SmoothedTrend.create!(
      asset_pair:,
      ohlc:,
      duration: ohlc.duration,
      range_position: ohlc.range_position,
      fast_smma: 1,
      slow_smma: 1,
      trend: :neutral,
      flip: false
    )

    SmoothedTrendService.expects(:call).never

    assert_no_changes -> { SmoothedTrend.count } do
      CreateSmoothedTrendsJob.perform_now(asset_pair:, duration: ohlc.duration)
    end
  end
end
