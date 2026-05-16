# frozen_string_literal: true

require 'test_helper'

# rubocop:disable Style/ClassAndModuleChildren
class SmoothedTrend::BulkBuilderTest < ActiveSupport::TestCase
  # rubocop:enable Style/ClassAndModuleChildren
  # Helper to create stub SMMA objects
  StubSmma = Struct.new(:interval, :value, keyword_init: true)

  # Helper to create complete SMMA set for a position
  def create_complete_smma_set(values: { 16 => 100.0, 19 => 98.0, 25 => 96.0, 28 => 94.0 })
    [
      StubSmma.new(interval: 16, value: values[16]),
      StubSmma.new(interval: 19, value: values[19]),
      StubSmma.new(interval: 25, value: values[25]),
      StubSmma.new(interval: 28, value: values[28])
    ]
  end

  # Helper to create incomplete SMMA set (missing one or more intervals)
  def create_incomplete_smma_set(missing_interval:)
    intervals = [16, 19, 25, 28] - [missing_interval]
    intervals.map { |interval| StubSmma.new(interval: interval, value: 100.0) }
  end

  test '#build_records returns empty array when smmas_by_position is empty' do
    asset_pair = asset_pairs(:atomusd)
    duration = 1.day

    builder = SmoothedTrend::BulkBuilder.new(previous_trend: nil)
    records = builder.build_records({}, asset_pair: asset_pair, duration: duration)

    assert_equal [], records
  end

  test '#build_records returns empty array when no complete SMMA sets exist' do
    asset_pair = asset_pairs(:atomusd)
    duration = 1.day

    # Create positions with incomplete SMMA data
    smmas_by_position = {
      1000 => create_incomplete_smma_set(missing_interval: 28),
      1001 => create_incomplete_smma_set(missing_interval: 16)
    }

    builder = SmoothedTrend::BulkBuilder.new(previous_trend: nil)
    records = builder.build_records(smmas_by_position, asset_pair: asset_pair, duration: duration)

    assert_equal [], records
  end

  test '#build_records creates correct record hash structure for single position' do
    asset_pair = asset_pairs(:atomusd)
    duration = 1.day
    iso8601_duration = duration.iso8601

    smmas_by_position = {
      1000 => create_complete_smma_set(values: { 16 => 100.0, 19 => 98.0, 25 => 96.0, 28 => 94.0 })
    }

    builder = SmoothedTrend::BulkBuilder.new(previous_trend: nil)
    records = builder.build_records(smmas_by_position, asset_pair: asset_pair, duration: duration)

    assert_equal 1, records.length

    record = records.first
    assert_equal asset_pair.id, record[:asset_pair_id]
    assert_equal iso8601_duration, record[:iso8601_duration]
    assert_equal 1000, record[:range_position]
    assert_equal 100.0, record[:fast_smma]
    assert_equal 94.0, record[:slow_smma]
    assert_includes %w[bullish neutral bearish], record[:trend]
    assert_in_delta Time.current, record[:created_at], 2.seconds
    assert_boolean record[:flip]
  end

  test '#build_records creates multiple records for multiple positions' do
    asset_pair = asset_pairs(:atomusd)
    duration = 1.day

    smmas_by_position = {
      1000 => create_complete_smma_set(values: { 16 => 100.0, 19 => 98.0, 25 => 96.0, 28 => 94.0 }),
      1001 => create_complete_smma_set(values: { 16 => 101.0, 19 => 99.0, 25 => 97.0, 28 => 95.0 }),
      1002 => create_complete_smma_set(values: { 16 => 102.0, 19 => 100.0, 25 => 98.0, 28 => 96.0 })
    }

    builder = SmoothedTrend::BulkBuilder.new(previous_trend: nil)
    records = builder.build_records(smmas_by_position, asset_pair: asset_pair, duration: duration)

    assert_equal 3, records.length
    assert_equal 1000, records[0][:range_position]
    assert_equal 1001, records[1][:range_position]
    assert_equal 1002, records[2][:range_position]
  end

  test '#build_records skips positions with incomplete SMMA data' do
    asset_pair = asset_pairs(:atomusd)
    duration = 1.day

    smmas_by_position = {
      1000 => create_complete_smma_set(values: { 16 => 100.0, 19 => 98.0, 25 => 96.0, 28 => 94.0 }),
      1001 => create_incomplete_smma_set(missing_interval: 28), # Missing interval 28
      1002 => create_complete_smma_set(values: { 16 => 102.0, 19 => 100.0, 25 => 98.0, 28 => 96.0 })
    }

    builder = SmoothedTrend::BulkBuilder.new(previous_trend: nil)
    records = builder.build_records(smmas_by_position, asset_pair: asset_pair, duration: duration)

    # Should only return 2 records (skipping position 1001)
    assert_equal 2, records.length
    assert_equal 1000, records[0][:range_position]
    assert_equal 1002, records[1][:range_position]
  end

  test '#build_records sets flip=true when previous_trend is nil (first position)' do
    asset_pair = asset_pairs(:atomusd)
    duration = 1.day

    smmas_by_position = {
      1000 => create_complete_smma_set(values: { 16 => 100.0, 19 => 98.0, 25 => 96.0, 28 => 94.0 })
    }

    builder = SmoothedTrend::BulkBuilder.new(previous_trend: nil)
    records = builder.build_records(smmas_by_position, asset_pair: asset_pair, duration: duration)

    assert records.first[:flip], 'Expected flip to be true when previous_trend is nil'
  end

  test '#build_records sets flip=true when trend changes from previous' do
    asset_pair = asset_pairs(:atomusd)
    duration = 1.day

    smmas_by_position = {
      1000 => create_complete_smma_set(values: { 16 => 100.0, 19 => 98.0, 25 => 96.0, 28 => 94.0 }), # bullish
      1001 => create_complete_smma_set(values: { 16 => 90.0, 19 => 92.0, 25 => 94.0, 28 => 96.0 }) # bearish
    }

    builder = SmoothedTrend::BulkBuilder.new(previous_trend: nil)
    records = builder.build_records(smmas_by_position, asset_pair: asset_pair, duration: duration)

    assert records[0][:flip], 'First position should have flip=true (no previous trend)'
    assert records[1][:flip], 'Second position should have flip=true (trend changed)'
    assert_equal 'bullish', records[0][:trend]
    assert_equal 'bearish', records[1][:trend]
  end

  test '#build_records sets flip=false when trend stays the same' do
    asset_pair = asset_pairs(:atomusd)
    duration = 1.day

    smmas_by_position = {
      1000 => create_complete_smma_set(values: { 16 => 100.0, 19 => 98.0, 25 => 96.0, 28 => 94.0 }), # bullish
      1001 => create_complete_smma_set(values: { 16 => 101.0, 19 => 99.0, 25 => 97.0, 28 => 95.0 })  # bullish
    }

    builder = SmoothedTrend::BulkBuilder.new(previous_trend: nil)
    records = builder.build_records(smmas_by_position, asset_pair: asset_pair, duration: duration)

    assert records[0][:flip], 'First position should have flip=true (no previous trend)'
    assert_not records[1][:flip], 'Second position should have flip=false (trend stayed the same)'
    assert_equal 'bullish', records[0][:trend]
    assert_equal 'bullish', records[1][:trend]
  end

  test '#build_records maintains state across multiple calls (previous_trend carries over)' do
    asset_pair = asset_pairs(:atomusd)
    duration = 1.day

    # First call: bullish trend
    smmas_by_position_first = {
      1000 => create_complete_smma_set(values: { 16 => 100.0, 19 => 98.0, 25 => 96.0, 28 => 94.0 })
    }

    builder = SmoothedTrend::BulkBuilder.new(previous_trend: nil)
    records_first = builder.build_records(smmas_by_position_first, asset_pair: asset_pair, duration: duration)

    assert_equal 'bullish', records_first.first[:trend]
    assert records_first.first[:flip], 'First call should have flip=true (no previous trend)'

    # Second call: still bullish (should not flip)
    smmas_by_position_second = {
      1001 => create_complete_smma_set(values: { 16 => 101.0, 19 => 99.0, 25 => 97.0, 28 => 95.0 })
    }

    records_second = builder.build_records(smmas_by_position_second, asset_pair: asset_pair, duration: duration)

    assert_equal 'bullish', records_second.first[:trend]
    assert_not records_second.first[:flip], 'Second call should have flip=false (trend stayed bullish)'

    # Third call: bearish (should flip)
    smmas_by_position_third = {
      1002 => create_complete_smma_set(values: { 16 => 90.0, 19 => 92.0, 25 => 94.0, 28 => 96.0 })
    }

    records_third = builder.build_records(smmas_by_position_third, asset_pair: asset_pair, duration: duration)

    assert_equal 'bearish', records_third.first[:trend]
    assert records_third.first[:flip], 'Third call should have flip=true (trend changed to bearish)'
  end

  test '#build_records orders results by range_position (hash keys order)' do
    asset_pair = asset_pairs(:atomusd)
    duration = 1.day

    # Intentionally use unordered hash (Ruby 1.9+ preserves insertion order)
    smmas_by_position = {
      1002 => create_complete_smma_set(values: { 16 => 102.0, 19 => 100.0, 25 => 98.0, 28 => 96.0 }),
      1000 => create_complete_smma_set(values: { 16 => 100.0, 19 => 98.0, 25 => 96.0, 28 => 94.0 }),
      1001 => create_complete_smma_set(values: { 16 => 101.0, 19 => 99.0, 25 => 97.0, 28 => 95.0 })
    }

    builder = SmoothedTrend::BulkBuilder.new(previous_trend: nil)
    records = builder.build_records(smmas_by_position, asset_pair: asset_pair, duration: duration)

    # Should preserve hash insertion order
    assert_equal 1002, records[0][:range_position]
    assert_equal 1000, records[1][:range_position]
    assert_equal 1001, records[2][:range_position]
  end

  test '#build_records handles multiple trend transitions' do
    asset_pair = asset_pairs(:atomusd)
    duration = 1.day

    smmas_by_position = {
      1000 => create_complete_smma_set(values: { 16 => 100.0, 19 => 98.0, 25 => 96.0, 28 => 94.0 }),  # bullish
      1001 => create_complete_smma_set(values: { 16 => 98.0, 19 => 100.0, 25 => 96.0, 28 => 94.0 }),  # neutral
      1002 => create_complete_smma_set(values: { 16 => 97.0, 19 => 99.0, 25 => 95.0, 28 => 93.0 }),   # neutral
      1003 => create_complete_smma_set(values: { 16 => 90.0, 19 => 92.0, 25 => 94.0, 28 => 96.0 })    # bearish
    }

    builder = SmoothedTrend::BulkBuilder.new(previous_trend: nil)
    records = builder.build_records(smmas_by_position, asset_pair: asset_pair, duration: duration)

    assert_equal 4, records.length

    # First: bullish with flip=true (no previous)
    assert_equal 'bullish', records[0][:trend]
    assert records[0][:flip]

    # Second: neutral with flip=true (changed from bullish)
    assert_equal 'neutral', records[1][:trend]
    assert records[1][:flip]

    # Third: neutral with flip=false (stayed neutral)
    assert_equal 'neutral', records[2][:trend]
    assert_not records[2][:flip]

    # Fourth: bearish with flip=true (changed from neutral)
    assert_equal 'bearish', records[3][:trend]
    assert records[3][:flip]
  end

  test '#build_records initializes with existing previous_trend from last SmoothedTrend' do
    asset_pair = asset_pairs(:atomusd)
    duration = 1.day

    # Start with bullish previous trend
    smmas_by_position = {
      1000 => create_complete_smma_set(values: { 16 => 101.0, 19 => 99.0, 25 => 97.0, 28 => 95.0 }) # bullish
    }

    builder = SmoothedTrend::BulkBuilder.new(previous_trend: 'bullish')
    records = builder.build_records(smmas_by_position, asset_pair: asset_pair, duration: duration)

    # Should not flip because previous was already bullish
    assert_equal 'bullish', records.first[:trend]
    assert_not records.first[:flip], 'Should not flip when continuing from previous bullish trend'
  end

  test '#calculate_trend returns bullish when fast > slow and no neutral conditions' do
    asset_pair = asset_pairs(:atomusd)
    duration = 1.day

    # fast (100) > slow (94) and neutral conditions don't apply = bullish
    smmas_by_position = {
      1000 => create_complete_smma_set(values: { 16 => 100.0, 19 => 98.0, 25 => 96.0, 28 => 94.0 })
    }

    builder = SmoothedTrend::BulkBuilder.new(previous_trend: nil)
    records = builder.build_records(smmas_by_position, asset_pair: asset_pair, duration: duration)

    assert_equal 'bullish', records.first[:trend]
  end

  test '#calculate_trend returns bearish when fast < slow and no neutral conditions' do
    asset_pair = asset_pairs(:atomusd)
    duration = 1.day

    # fast (90) < slow (96) and neutral conditions don't apply = bearish
    smmas_by_position = {
      1000 => create_complete_smma_set(values: { 16 => 90.0, 19 => 92.0, 25 => 94.0, 28 => 96.0 })
    }

    builder = SmoothedTrend::BulkBuilder.new(previous_trend: nil)
    records = builder.build_records(smmas_by_position, asset_pair: asset_pair, duration: duration)

    assert_equal 'bearish', records.first[:trend]
  end

  test '#calculate_trend returns neutral when neutral_up condition is met' do
    asset_pair = asset_pairs(:atomusd)
    duration = 1.day

    # fast (100) > slow (94) = bullish?=true
    # BUT fast (100) < medium_fast (102) which contradicts bullish
    # This means: (fast < medium_fast) == bullish? => true == true => neutral_up
    smmas_by_position = {
      1000 => create_complete_smma_set(values: { 16 => 100.0, 19 => 102.0, 25 => 96.0, 28 => 94.0 })
    }

    builder = SmoothedTrend::BulkBuilder.new(previous_trend: nil)
    records = builder.build_records(smmas_by_position, asset_pair: asset_pair, duration: duration)

    assert_equal 'neutral', records.first[:trend]
  end

  test '#calculate_trend returns neutral when neutral_down condition is met' do
    asset_pair = asset_pairs(:atomusd)
    duration = 1.day

    # fast (100) > slow (94) = bullish?=true
    # BUT medium_slow (92) < slow (94) which aligns with bullish
    # This means: (medium_slow < slow) == bullish? => true == true => neutral_down
    smmas_by_position = {
      1000 => create_complete_smma_set(values: { 16 => 100.0, 19 => 98.0, 25 => 92.0, 28 => 94.0 })
    }

    builder = SmoothedTrend::BulkBuilder.new(previous_trend: nil)
    records = builder.build_records(smmas_by_position, asset_pair: asset_pair, duration: duration)

    assert_equal 'neutral', records.first[:trend]
  end

  private

  # Helper to assert boolean value (true or false, not nil)
  def assert_boolean(value)
    assert_includes [true, false], value, "Expected boolean value, got #{value.inspect}"
  end
end
