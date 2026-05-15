# frozen_string_literal: true

require 'test_helper'

class SmoothedTrendTest < ActiveSupport::TestCase
  # Helper method to create test OHLC data
  # rubocop:disable Metrics/ParameterLists
  def create_test_ohlc(asset_pair:, iso8601_duration:, range_position:, high: 100, low: 90, open: 95, close: 98,
                       volume: 1000)
    # rubocop:enable Metrics/ParameterLists
    Ohlc.create!(
      asset_pair:,
      iso8601_duration:,
      range_position:,
      high:,
      low:,
      open:,
      close:,
      volume:
    )
  end

  # Helper method to create a complete set of SMMAs for a position
  def create_smma_set(asset_pair:, iso8601_duration:, range_position:,
                      values: { 16 => 100.0, 19 => 98.0, 25 => 96.0, 28 => 94.0 })
    values.each do |interval, value|
      SmoothedMovingAverage.create!(
        asset_pair:,
        iso8601_duration:,
        range_position:,
        interval:,
        value:
      )
    end
  end

  test '.bulk_create_for_duration creates SmoothedTrends when none exist yet' do
    asset_pair = asset_pairs(:atomusd)
    duration = 1.day

    # First create all SMMAs
    SmoothedMovingAverage::INTERVALS.each do |interval|
      SmoothedMovingAverage.bulk_create_interval(asset_pair:, duration:, interval:)
    end

    # Count positions that have all 4 intervals (this is how many trends we should create)
    expected_count = SmoothedMovingAverage.with_generated_intervals
                                          .where(asset_pair:)
                                          .by_duration(duration)
                                          .select(:range_position)
                                          .distinct
                                          .count

    assert_difference -> { SmoothedTrend.where(asset_pair:).by_duration(duration).count }, expected_count do
      SmoothedTrend.bulk_create_for_duration(asset_pair:, duration:)
    end
  end

  test '.bulk_create_for_duration starts after the last existing SmoothedTrend' do
    asset_pair = asset_pairs(:atomusd)
    duration = 1.day

    # Create all SMMAs
    SmoothedMovingAverage::INTERVALS.each do |interval|
      SmoothedMovingAverage.bulk_create_interval(asset_pair:, duration:, interval:)
    end

    # Create first batch of SmoothedTrends
    SmoothedTrend.bulk_create_for_duration(asset_pair:, duration:)

    # Delete the last 3 SmoothedTrends to simulate new data
    last_trend = SmoothedTrend.where(asset_pair:).by_duration(duration).order(range_position: :desc).first
    SmoothedTrend.where(asset_pair:, iso8601_duration: duration.iso8601)
                 .where(range_position: (last_trend.range_position - 2)..)
                 .delete_all

    # Should create 3 more trends starting after the new last one
    assert_difference -> { SmoothedTrend.where(asset_pair:).by_duration(duration).count }, 3 do
      SmoothedTrend.bulk_create_for_duration(asset_pair:, duration:)
    end
  end

  test '.bulk_create_for_duration correctly detects flip when trend changes from previous' do
    asset_pair = asset_pairs(:atomusd)
    duration = 1.day
    iso8601_duration = duration.iso8601

    # Create OHLCs
    create_test_ohlc(asset_pair:, iso8601_duration:, range_position: 1000)
    create_test_ohlc(asset_pair:, iso8601_duration:, range_position: 1001)

    # First position: bullish
    create_smma_set(
      asset_pair:,
      iso8601_duration:,
      range_position: 1000,
      values: { 16 => 100.0, 19 => 98.0, 25 => 96.0, 28 => 94.0 }
    )

    # Second position: bearish (trend changed)
    create_smma_set(
      asset_pair:,
      iso8601_duration:,
      range_position: 1001,
      values: { 16 => 90.0, 19 => 92.0, 25 => 94.0, 28 => 96.0 }
    )

    SmoothedTrend.bulk_create_for_duration(asset_pair:, duration:)

    trend1 = SmoothedTrend.find_by(asset_pair:, iso8601_duration:, range_position: 1000)
    trend2 = SmoothedTrend.find_by(asset_pair:, iso8601_duration:, range_position: 1001)

    # First trend should have flip=true (no previous trend)
    assert trend1.flip

    # Second trend should have flip=true (trend changed from bullish to bearish)
    assert trend2.flip
    assert_equal 'bullish', trend1.trend
    assert_equal 'bearish', trend2.trend
  end

  test '.bulk_create_for_duration correctly sets flip to false when trend does not change' do
    asset_pair = asset_pairs(:atomusd)
    duration = 1.day
    iso8601_duration = duration.iso8601

    # Create OHLCs
    create_test_ohlc(asset_pair:, iso8601_duration:, range_position: 1000)
    create_test_ohlc(asset_pair:, iso8601_duration:, range_position: 1001)

    # Both positions: bullish (no trend change)
    create_smma_set(
      asset_pair:,
      iso8601_duration:,
      range_position: 1000,
      values: { 16 => 100.0, 19 => 98.0, 25 => 96.0, 28 => 94.0 }
    )

    create_smma_set(
      asset_pair:,
      iso8601_duration:,
      range_position: 1001,
      values: { 16 => 101.0, 19 => 99.0, 25 => 97.0, 28 => 95.0 }
    )

    SmoothedTrend.bulk_create_for_duration(asset_pair:, duration:)

    trend1 = SmoothedTrend.find_by(asset_pair:, iso8601_duration:, range_position: 1000)
    trend2 = SmoothedTrend.find_by(asset_pair:, iso8601_duration:, range_position: 1001)

    # First trend should have flip=true (no previous trend)
    assert trend1.flip

    # Second trend should have flip=false (trend stayed bullish)
    assert_not trend2.flip
    assert_equal 'bullish', trend1.trend
    assert_equal 'bullish', trend2.trend
  end

  test '.bulk_create_for_duration only creates SmoothedTrends where all 4 SMMA values exist' do
    asset_pair = asset_pairs(:atomusd)
    duration = 1.day
    iso8601_duration = duration.iso8601

    # Create OHLCs
    create_test_ohlc(asset_pair:, iso8601_duration:, range_position: 1000)
    create_test_ohlc(asset_pair:, iso8601_duration:, range_position: 1001)

    # Position 1000: has all 4 intervals
    create_smma_set(
      asset_pair:,
      iso8601_duration:,
      range_position: 1000,
      values: { 16 => 100.0, 19 => 98.0, 25 => 96.0, 28 => 94.0 }
    )

    # Position 1001: missing interval 28
    SmoothedMovingAverage.create!(asset_pair:, iso8601_duration:, range_position: 1001, interval: 16, value: 100.0)
    SmoothedMovingAverage.create!(asset_pair:, iso8601_duration:, range_position: 1001, interval: 19, value: 98.0)
    SmoothedMovingAverage.create!(asset_pair:, iso8601_duration:, range_position: 1001, interval: 25, value: 96.0)

    SmoothedTrend.bulk_create_for_duration(asset_pair:, duration:)

    # Should only create trend for position 1000
    assert SmoothedTrend.exists?(asset_pair:, iso8601_duration:, range_position: 1000)
    assert_not SmoothedTrend.exists?(asset_pair:, iso8601_duration:, range_position: 1001)
  end

  test '.bulk_create_for_duration handles batch processing of multiple records' do
    asset_pair = asset_pairs(:atomusd)
    duration = 1.day
    iso8601_duration = duration.iso8601

    # Create 10 OHLCs with complete SMMA sets
    10.times do |i|
      range_position = 1000 + i
      create_test_ohlc(asset_pair:, iso8601_duration:, range_position:)

      create_smma_set(
        asset_pair:,
        iso8601_duration:,
        range_position:,
        values: { 16 => 100.0, 19 => 98.0, 25 => 96.0, 28 => 94.0 }
      )
    end

    assert_difference -> { SmoothedTrend.where(asset_pair:).by_duration(duration).count }, 10 do
      SmoothedTrend.bulk_create_for_duration(asset_pair:, duration:)
    end

    # Verify all 10 trends were created with correct range_positions
    10.times do |i|
      range_position = 1000 + i
      assert SmoothedTrend.exists?(asset_pair:, iso8601_duration:, range_position:)
    end
  end

  test '.bulk_create_for_duration returns nil when no SMMAs exist' do
    asset_pair = asset_pairs(:atomusd)
    duration = 1.day

    result = SmoothedTrend.bulk_create_for_duration(asset_pair:, duration:)

    assert_nil result
  end

  test '.bulk_create_for_duration works with different durations' do
    asset_pair = asset_pairs(:atomusd)
    duration = 2.days
    iso8601_duration = duration.iso8601

    # Create OHLC
    create_test_ohlc(asset_pair:, iso8601_duration:, range_position: 1000)

    # Create SMMAs
    create_smma_set(
      asset_pair:,
      iso8601_duration:,
      range_position: 1000,
      values: { 16 => 100.0, 19 => 98.0, 25 => 96.0, 28 => 94.0 }
    )

    assert_difference -> { SmoothedTrend.where(asset_pair:).by_duration(duration).count }, 1 do
      SmoothedTrend.bulk_create_for_duration(asset_pair:, duration:)
    end
  end

  test '.bulk_create_for_duration correctly handles multiple trend transitions with flip flags' do
    asset_pair = asset_pairs(:atomusd)
    duration = 1.day
    iso8601_duration = duration.iso8601

    # Create OHLCs for multiple transitions
    create_test_ohlc(asset_pair:, iso8601_duration:, range_position: 1000)
    create_test_ohlc(asset_pair:, iso8601_duration:, range_position: 1001)
    create_test_ohlc(asset_pair:, iso8601_duration:, range_position: 1002)
    create_test_ohlc(asset_pair:, iso8601_duration:, range_position: 1003)
    create_test_ohlc(asset_pair:, iso8601_duration:, range_position: 1004)

    # Position 1000: bullish
    create_smma_set(
      asset_pair:,
      iso8601_duration:,
      range_position: 1000,
      values: { 16 => 100.0, 19 => 98.0, 25 => 96.0, 28 => 94.0 }
    )

    # Position 1001: neutral (trend change from bullish)
    create_smma_set(
      asset_pair:,
      iso8601_duration:,
      range_position: 1001,
      values: { 16 => 98.0, 19 => 100.0, 25 => 96.0, 28 => 94.0 }
    )

    # Position 1002: neutral (no trend change)
    create_smma_set(
      asset_pair:,
      iso8601_duration:,
      range_position: 1002,
      values: { 16 => 97.0, 19 => 99.0, 25 => 95.0, 28 => 93.0 }
    )

    # Position 1003: neutral (no trend change)
    create_smma_set(
      asset_pair:,
      iso8601_duration:,
      range_position: 1003,
      values: { 16 => 96.0, 19 => 98.0, 25 => 94.0, 28 => 92.0 }
    )

    # Position 1004: bearish (trend change from neutral)
    create_smma_set(
      asset_pair:,
      iso8601_duration:,
      range_position: 1004,
      values: { 16 => 90.0, 19 => 92.0, 25 => 94.0, 28 => 96.0 }
    )

    SmoothedTrend.bulk_create_for_duration(asset_pair:, duration:)

    bullish_trend = SmoothedTrend.find_by(asset_pair:, iso8601_duration:, range_position: 1000)
    neutral_trend1 = SmoothedTrend.find_by(asset_pair:, iso8601_duration:, range_position: 1001)
    neutral_trend2 = SmoothedTrend.find_by(asset_pair:, iso8601_duration:, range_position: 1002)
    neutral_trend3 = SmoothedTrend.find_by(asset_pair:, iso8601_duration:, range_position: 1003)
    bearish_trend = SmoothedTrend.find_by(asset_pair:, iso8601_duration:, range_position: 1004)

    # First trend should be bullish with flip=true (no previous trend)
    assert_equal 'bullish', bullish_trend.trend
    assert bullish_trend.flip

    # Second trend should be neutral with flip=true (changed from bullish)
    assert_equal 'neutral', neutral_trend1.trend
    assert neutral_trend1.flip

    # Third trend should be neutral with flip=false (stayed neutral)
    assert_equal 'neutral', neutral_trend2.trend
    assert_not neutral_trend2.flip

    # Fourth trend should be neutral with flip=false (stayed neutral)
    assert_equal 'neutral', neutral_trend3.trend
    assert_not neutral_trend3.flip

    # Fifth trend should be bearish with flip=true (changed from neutral)
    assert_equal 'bearish', bearish_trend.trend
    assert bearish_trend.flip
  end
end
