# frozen_string_literal: true

require 'test_helper'

class SmoothedTrend::BulkQueryTest < ActiveSupport::TestCase
  # Helper method to create an OHLC (SmoothedTrend requires this)
  # rubocop:disable Metrics/ParameterLists
  def create_test_ohlc(asset_pair:, iso8601_duration:, range_position:, high: 100, low: 90,
                       open: 95, close: 98, volume: 1000)
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
  # rubocop:enable Metrics/ParameterLists

  # Helper method to create a complete set of SMMAs for a position
  # rubocop:disable Metrics/MethodLength
  def create_smma_set(asset_pair:, iso8601_duration:, range_position:,
                      values: { 16 => 100.0, 19 => 98.0, 25 => 96.0, 28 => 94.0 })
    # Ensure OHLC exists first (SMMAs have a foreign key constraint)
    create_test_ohlc(asset_pair:, iso8601_duration:, range_position:) unless Ohlc.exists?(
      asset_pair:, iso8601_duration:, range_position:
    )

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
  # rubocop:enable Metrics/MethodLength

  # Helper method to create a SmoothedTrend
  # rubocop:disable Metrics/MethodLength
  def create_smoothed_trend(asset_pair:, iso8601_duration:, range_position:, trend: 'bullish', flip: true)
    # Ensure OHLC exists first
    create_test_ohlc(asset_pair:, iso8601_duration:, range_position:) unless Ohlc.exists?(
      asset_pair:, iso8601_duration:, range_position:
    )

    SmoothedTrend.create!(
      asset_pair:,
      iso8601_duration:,
      range_position:,
      fast_smma: 100.0,
      slow_smma: 94.0,
      trend:,
      flip:
    )
  end
  # rubocop:enable Metrics/MethodLength

  test '#last_trend returns the most recent SmoothedTrend by range_position' do
    asset_pair = asset_pairs(:atomusd)
    duration = 1.day
    iso8601_duration = duration.iso8601

    # Create SmoothedTrends at different positions
    create_smoothed_trend(asset_pair:, iso8601_duration:, range_position: 100)
    create_smoothed_trend(asset_pair:, iso8601_duration:, range_position: 200)
    last = create_smoothed_trend(asset_pair:, iso8601_duration:, range_position: 300)

    query = SmoothedTrend::BulkQuery.new(asset_pair:, duration:)

    assert_equal last, query.last_trend
    assert_equal 300, query.last_trend.range_position
  end

  test '#last_trend returns nil when no SmoothedTrends exist' do
    asset_pair = asset_pairs(:atomusd)
    duration = 1.day

    query = SmoothedTrend::BulkQuery.new(asset_pair:, duration:)

    assert_nil query.last_trend
  end

  test '#last_trend returns nil when SmoothedTrends exist for different asset_pair' do
    atomusd = asset_pairs(:atomusd)
    btcusd = asset_pairs(:btcusd)
    duration = 1.day

    # Create trend for btcusd
    create_smoothed_trend(asset_pair: btcusd, iso8601_duration: duration.iso8601, range_position: 100)

    query = SmoothedTrend::BulkQuery.new(asset_pair: atomusd, duration:)

    assert_nil query.last_trend
  end

  test '#last_trend returns nil when SmoothedTrends exist for different duration' do
    asset_pair = asset_pairs(:atomusd)

    # Create trend for 2.days
    create_smoothed_trend(asset_pair:, iso8601_duration: 2.days.iso8601, range_position: 100)

    query = SmoothedTrend::BulkQuery.new(asset_pair:, duration: 1.day)

    assert_nil query.last_trend
  end

  test '#empty? returns true when no SMMAs exist' do
    asset_pair = asset_pairs(:atomusd)
    duration = 1.day

    query = SmoothedTrend::BulkQuery.new(asset_pair:, duration:)

    assert query.empty?
  end

  test '#empty? returns false when SMMAs exist with all 4 intervals' do
    asset_pair = asset_pairs(:atomusd)
    duration = 1.day

    # Create a complete set of SMMAs
    create_smma_set(
      asset_pair:,
      iso8601_duration: duration.iso8601,
      range_position: 100
    )

    query = SmoothedTrend::BulkQuery.new(asset_pair:, duration:)

    assert_not query.empty?
  end

  test '#empty? returns true when SMMAs exist but not all 4 intervals are present' do
    asset_pair = asset_pairs(:atomusd)
    duration = 1.day
    iso8601_duration = duration.iso8601

    # Create OHLC first
    create_test_ohlc(asset_pair:, iso8601_duration:, range_position: 100)

    # Create incomplete set (only 3 intervals)
    SmoothedMovingAverage.create!(asset_pair:, iso8601_duration:, range_position: 100, interval: 16, value: 100.0)
    SmoothedMovingAverage.create!(asset_pair:, iso8601_duration:, range_position: 100, interval: 19, value: 98.0)
    SmoothedMovingAverage.create!(asset_pair:, iso8601_duration:, range_position: 100, interval: 25, value: 96.0)

    query = SmoothedTrend::BulkQuery.new(asset_pair:, duration:)

    assert query.empty?
  end

  test '#empty? returns false when SMMAs exist starting after a last_trend position' do
    asset_pair = asset_pairs(:atomusd)
    duration = 1.day
    iso8601_duration = duration.iso8601

    # Create a SmoothedTrend at position 100
    create_smoothed_trend(asset_pair:, iso8601_duration:, range_position: 100)

    # Create SMMAs at position 101 (after last_trend)
    create_smma_set(asset_pair:, iso8601_duration:, range_position: 101)

    query = SmoothedTrend::BulkQuery.new(asset_pair:, duration:)

    assert_not query.empty?
  end

  test '#empty? returns true when SMMAs exist only before the last_trend position' do
    asset_pair = asset_pairs(:atomusd)
    duration = 1.day
    iso8601_duration = duration.iso8601

    # Create a SmoothedTrend at position 100
    create_smoothed_trend(asset_pair:, iso8601_duration:, range_position: 100)

    # Create SMMAs at position 99 (before last_trend)
    create_smma_set(asset_pair:, iso8601_duration:, range_position: 99)

    query = SmoothedTrend::BulkQuery.new(asset_pair:, duration:)

    assert query.empty?
  end

  test '#each_batch yields grouped SMMAs to the block' do
    asset_pair = asset_pairs(:atomusd)
    duration = 1.day
    iso8601_duration = duration.iso8601

    # Create complete SMMA sets for two positions
    create_smma_set(asset_pair:, iso8601_duration:, range_position: 100)
    create_smma_set(asset_pair:, iso8601_duration:, range_position: 101)

    query = SmoothedTrend::BulkQuery.new(asset_pair:, duration:)

    batches = []
    query.each_batch do |batch|
      batches << batch
    end

    assert_not_empty batches
    assert batches.first.is_a?(Hash), 'Batch should be a Hash'
  end

  test '#each_batch groups SMMAs by range_position correctly' do
    asset_pair = asset_pairs(:atomusd)
    duration = 1.day
    iso8601_duration = duration.iso8601

    # Create complete SMMA sets for two positions
    create_smma_set(asset_pair:, iso8601_duration:, range_position: 100)
    create_smma_set(asset_pair:, iso8601_duration:, range_position: 101)

    query = SmoothedTrend::BulkQuery.new(asset_pair:, duration:)

    all_positions = []
    query.each_batch do |batch|
      all_positions.concat(batch.keys)
    end

    assert_includes all_positions, 100
    assert_includes all_positions, 101
  end

  test '#each_batch yields each group with all 4 SMMA intervals' do
    asset_pair = asset_pairs(:atomusd)
    duration = 1.day
    iso8601_duration = duration.iso8601

    # Create complete SMMA set
    create_smma_set(asset_pair:, iso8601_duration:, range_position: 100)

    query = SmoothedTrend::BulkQuery.new(asset_pair:, duration:)

    query.each_batch do |batch|
      smmas = batch[100]
      assert_equal 4, smmas.count, 'Should have all 4 intervals'
      assert_equal [16, 19, 25, 28], smmas.map(&:interval).sort
    end
  end

  test '#each_batch only includes positions with all 4 intervals' do
    asset_pair = asset_pairs(:atomusd)
    duration = 1.day
    iso8601_duration = duration.iso8601

    # Create complete SMMA set at position 100
    create_smma_set(asset_pair:, iso8601_duration:, range_position: 100)

    # Create OHLC for position 101
    create_test_ohlc(asset_pair:, iso8601_duration:, range_position: 101)

    # Create incomplete SMMA set at position 101 (missing interval 28)
    SmoothedMovingAverage.create!(asset_pair:, iso8601_duration:, range_position: 101, interval: 16, value: 100.0)
    SmoothedMovingAverage.create!(asset_pair:, iso8601_duration:, range_position: 101, interval: 19, value: 98.0)
    SmoothedMovingAverage.create!(asset_pair:, iso8601_duration:, range_position: 101, interval: 25, value: 96.0)

    query = SmoothedTrend::BulkQuery.new(asset_pair:, duration:)

    all_positions = []
    query.each_batch do |batch|
      all_positions.concat(batch.keys)
    end

    # Should only include position 100, not 101
    assert_includes all_positions, 100
    assert_not_includes all_positions, 101
  end

  test '#each_batch starts from position 0 when no last_trend exists' do
    asset_pair = asset_pairs(:atomusd)
    duration = 1.day
    iso8601_duration = duration.iso8601

    # Create SMMA sets starting from position 0
    create_smma_set(asset_pair:, iso8601_duration:, range_position: 0)
    create_smma_set(asset_pair:, iso8601_duration:, range_position: 1)

    query = SmoothedTrend::BulkQuery.new(asset_pair:, duration:)

    all_positions = []
    query.each_batch do |batch|
      all_positions.concat(batch.keys)
    end

    assert_includes all_positions, 0
    assert_includes all_positions, 1
  end

  test '#each_batch starts from last_trend.range_position + 1 when last_trend exists' do
    asset_pair = asset_pairs(:atomusd)
    duration = 1.day
    iso8601_duration = duration.iso8601

    # Create SmoothedTrend at position 100
    create_smoothed_trend(asset_pair:, iso8601_duration:, range_position: 100)

    # Create SMMA sets at positions 99, 100, 101, and 102
    create_smma_set(asset_pair:, iso8601_duration:, range_position: 99)
    create_smma_set(asset_pair:, iso8601_duration:, range_position: 100)
    create_smma_set(asset_pair:, iso8601_duration:, range_position: 101)
    create_smma_set(asset_pair:, iso8601_duration:, range_position: 102)

    query = SmoothedTrend::BulkQuery.new(asset_pair:, duration:)

    all_positions = []
    query.each_batch do |batch|
      all_positions.concat(batch.keys)
    end

    # Should only include positions 101 and 102 (after position 100)
    assert_not_includes all_positions, 99
    assert_not_includes all_positions, 100
    assert_includes all_positions, 101
    assert_includes all_positions, 102
  end

  test '#each_batch filters by asset_pair' do
    atomusd = asset_pairs(:atomusd)
    btcusd = asset_pairs(:btcusd)
    duration = 1.day

    # Create SMMAs for both asset pairs
    create_smma_set(asset_pair: atomusd, iso8601_duration: duration.iso8601, range_position: 100)
    create_smma_set(asset_pair: btcusd, iso8601_duration: duration.iso8601, range_position: 100)

    query = SmoothedTrend::BulkQuery.new(asset_pair: atomusd, duration:)

    all_smmas = []
    query.each_batch do |batch|
      batch.each_value { |smmas| all_smmas.concat(smmas) }
    end

    # All SMMAs should belong to atomusd
    assert(all_smmas.all? { |smma| smma.asset_pair == atomusd })
    assert(all_smmas.none? { |smma| smma.asset_pair == btcusd })
  end

  test '#each_batch filters by duration' do
    asset_pair = asset_pairs(:atomusd)

    # Create SMMAs for two different durations
    create_smma_set(asset_pair:, iso8601_duration: 1.day.iso8601, range_position: 100)
    create_smma_set(asset_pair:, iso8601_duration: 2.days.iso8601, range_position: 100)

    query = SmoothedTrend::BulkQuery.new(asset_pair:, duration: 1.day)

    all_smmas = []
    query.each_batch do |batch|
      batch.each_value { |smmas| all_smmas.concat(smmas) }
    end

    # All SMMAs should belong to 1.day duration
    assert(all_smmas.all? { |smma| smma.iso8601_duration == 1.day.iso8601 })
    assert(all_smmas.none? { |smma| smma.iso8601_duration == 2.days.iso8601 })
  end

  test '#each_batch orders results by range_position' do
    asset_pair = asset_pairs(:atomusd)
    duration = 1.day
    iso8601_duration = duration.iso8601

    # Create SMMA sets in random order
    create_smma_set(asset_pair:, iso8601_duration:, range_position: 102)
    create_smma_set(asset_pair:, iso8601_duration:, range_position: 100)
    create_smma_set(asset_pair:, iso8601_duration:, range_position: 101)

    query = SmoothedTrend::BulkQuery.new(asset_pair:, duration:)

    all_positions = []
    query.each_batch do |batch|
      all_positions.concat(batch.keys)
    end

    assert_equal [100, 101, 102], all_positions.sort
  end
end
