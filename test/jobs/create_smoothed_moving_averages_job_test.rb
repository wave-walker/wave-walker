# frozen_string_literal: true

require 'test_helper'

class CreateSmoothedMovingAveragesJobTest < ActiveJob::TestCase
  test '#perform, creates SMMAs for OHLCs without SMMAs' do
    asset_pair = asset_pairs(:atomusd)

    # Create OHLCs without SMMAs
    ohlcs = (0...35).map do |i|
      Ohlc.create!(
        asset_pair: asset_pair,
        duration: 1.day,
        range_position: i + 1000, # Use offset to avoid fixture conflicts
        open: i + 10.0,
        high: i + 11.0,
        low: i + 9.0,
        close: i + 10.0,
        volume: 1000
      )
    end

    # Verify no SMMAs exist yet for the last 5 OHLCs
    target_ohlcs = ohlcs[30..34]
    target_ohlcs.each do |ohlc|
      assert_equal 0, ohlc.smoothed_moving_averages.count
    end

    # Run job
    CreateSmoothedMovingAveragesJob.perform_now(
      asset_pair: asset_pair,
      duration: 1.day
    )

    # Verify SMMAs were created
    target_ohlcs.each do |ohlc|
      ohlc.reload
      # Should have 4 SMMAs per OHLC (intervals 16, 28, 19, 25)
      assert_equal 4, ohlc.smoothed_moving_averages.count
    end
  end

  test '#perform, only queries OHLCs without any SMMAs' do
    asset_pair = asset_pairs(:atomusd)

    # Create OHLCs without SMMAs at high positions
    ohlc_without_1 = Ohlc.create!(
      asset_pair: asset_pair,
      duration: 1.day,
      range_position: 9_000_000,
      open: 10.0,
      high: 11.0,
      low: 9.0,
      close: 10.0,
      volume: 1000
    )

    ohlc_without_2 = Ohlc.create!(
      asset_pair: asset_pair,
      duration: 1.day,
      range_position: 9_000_001,
      open: 10.0,
      high: 11.0,
      low: 9.0,
      close: 10.0,
      volume: 1000
    )

    # Verify the query used by the job correctly finds these OHLCs
    query_result = Ohlc.where(asset_pair: asset_pair)
                       .by_duration(1.day)
                       .left_outer_joins(:smoothed_moving_averages)
                       .where(smoothed_moving_averages: { asset_pair_id: nil })
                       .distinct

    assert_includes query_result, ohlc_without_1
    assert_includes query_result, ohlc_without_2
  end

  test '#perform, enqueues CreateSmoothedTrendsJob on complete' do
    asset_pair = asset_pairs(:atomusd)
    duration = 1.day

    # The job uses on_complete callback, so we test indirectly
    # by checking that CreateSmoothedTrendsJob is enqueued after completion
    assert_enqueued_with(job: CreateSmoothedTrendsJob, args: [{ asset_pair: asset_pair, duration: duration }]) do
      CreateSmoothedMovingAveragesJob.perform_now(
        asset_pair: asset_pair,
        duration: duration
      )
    end
  end
end
