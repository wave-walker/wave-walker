# frozen_string_literal: true

require 'test_helper'

class CreateSmoothedTrendsJobTest < ActiveJob::TestCase
  test '#perform, creates smoothed trends for ohlcs without one' do
    asset_pair = asset_pairs(:atomusd)
    ohlc_with_trend = ohlcs(:atom20221201)
    ohlc_without_trend = ohlcs(:atom20221202)

    SmoothedTrend.create!(
      asset_pair:,
      ohlc: ohlc_with_trend,
      duration: 1.day,
      range_position: ohlc_with_trend.range_position,
      fast_smma: 1,
      slow_smma: 1,
      trend: :neutral,
      flip: false
    )

    SmoothedTrendService.expects(:call).with(ohlc_without_trend).once
    SmoothedTrendService.expects(:call).with(ohlc_with_trend).never

    CreateSmoothedTrendsJob.perform_now(asset_pair:, duration: 1.day)
  end

  test '#perform, skips ohlcs that already have a trend' do
    asset_pair = asset_pairs(:atomusd)
    ohlc = ohlcs(:atom20221203)

    SmoothedTrend.create!(
      asset_pair:,
      ohlc:,
      duration: 1.day,
      range_position: ohlc.range_position,
      fast_smma: 1,
      slow_smma: 1,
      trend: :neutral,
      flip: false
    )

    SmoothedTrendService.expects(:call).never

    assert_no_changes -> { SmoothedTrend.count } do
      CreateSmoothedTrendsJob.perform_now(asset_pair:, duration: 1.day)
    end
  end
end
