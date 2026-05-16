# frozen_string_literal: true

require 'test_helper'

class SmoothedTrend::UnprocessedSmmasQueryTest < ActiveSupport::TestCase
  test 'returns empty result when no SMMAs exist' do
    asset_pair = asset_pairs(:atomusd)
    duration = 1.day

    query = SmoothedTrend::UnprocessedSmmasQuery.new(asset_pair:, duration:)
    results = query.call

    assert_empty results
  end

  test 'returns empty result when only some intervals exist (missing interval 28)' do
    asset_pair = asset_pairs(:atomusd)
    duration = 1.day
    iso8601_duration = duration.iso8601

    Ohlc.create!(asset_pair:, iso8601_duration:, range_position: 100, high: 1, low: 1, open: 1, close: 1, volume: 1)
    Ohlc.create!(asset_pair:, iso8601_duration:, range_position: 101, high: 1, low: 1, open: 1, close: 1, volume: 1)

    # Interval 28 is missing.
    SmoothedMovingAverage.create!(asset_pair:, iso8601_duration:, range_position: 100, interval: 16, value: 1)
    SmoothedMovingAverage.create!(asset_pair:, iso8601_duration:, range_position: 100, interval: 19, value: 1)
    SmoothedMovingAverage.create!(asset_pair:, iso8601_duration:, range_position: 100, interval: 25, value: 1)

    # Interval 16 is missing.
    SmoothedMovingAverage.create!(asset_pair:, iso8601_duration:, range_position: 101, interval: 19, value: 1)
    SmoothedMovingAverage.create!(asset_pair:, iso8601_duration:, range_position: 101, interval: 25, value: 1)
    SmoothedMovingAverage.create!(asset_pair:, iso8601_duration:, range_position: 101, interval: 28, value: 1)

    assert_empty SmoothedTrend::UnprocessedSmmasQuery.new(asset_pair:, duration:).call
  end

  test 'returns empty result when all 4 intervals exist but SmoothedTrend already exists' do
    asset_pair = asset_pairs(:atomusd)
    duration = 1.day
    iso8601_duration = duration.iso8601

    Ohlc.create!(asset_pair:, iso8601_duration:, range_position: 100, high: 1, low: 1, open: 1, close: 1, volume: 1)

    SmoothedMovingAverage.create!(asset_pair:, iso8601_duration:, range_position: 100, interval: 16, value: 1)
    SmoothedMovingAverage.create!(asset_pair:, iso8601_duration:, range_position: 100, interval: 19, value: 1)
    SmoothedMovingAverage.create!(asset_pair:, iso8601_duration:, range_position: 100, interval: 25, value: 1)
    SmoothedMovingAverage.create!(asset_pair:, iso8601_duration:, range_position: 100, interval: 28, value: 1)

    SmoothedTrend.create!(asset_pair:, iso8601_duration:, range_position: 100, fast_smma: 1, slow_smma: 1,
                          trend: 'bullish', flip: true)

    assert_empty SmoothedTrend::UnprocessedSmmasQuery.new(asset_pair:, duration:).call
  end

  test 'returns SMMA position when all 4 intervals exist and NO SmoothedTrend exists' do
    asset_pair = asset_pairs(:atomusd)
    duration = 1.day
    iso8601_duration = duration.iso8601

    Ohlc.create!(asset_pair:, iso8601_duration:, range_position: 100, high: 1, low: 1, open: 1, close: 1, volume: 1)

    SmoothedMovingAverage.create!(asset_pair:, iso8601_duration:, range_position: 100, interval: 16, value: 1)
    SmoothedMovingAverage.create!(asset_pair:, iso8601_duration:, range_position: 100, interval: 19, value: 1)
    SmoothedMovingAverage.create!(asset_pair:, iso8601_duration:, range_position: 100, interval: 25, value: 1)
    SmoothedMovingAverage.create!(asset_pair:, iso8601_duration:, range_position: 100, interval: 28, value: 1)

    assert_equal 1, SmoothedTrend::UnprocessedSmmasQuery.new(asset_pair:, duration:).call.count
  end

  test 'returns multiple positions in chronological order by range_position' do
    asset_pair = asset_pairs(:atomusd)
    duration = 1.day
    iso8601_duration = duration.iso8601

    Ohlc.create!(asset_pair:, iso8601_duration:, range_position: 102, high: 1, low: 1, open: 1, close: 1, volume: 1)

    SmoothedMovingAverage.create!(asset_pair:, iso8601_duration:, range_position: 102, interval: 16, value: 1)
    SmoothedMovingAverage.create!(asset_pair:, iso8601_duration:, range_position: 102, interval: 19, value: 1)
    SmoothedMovingAverage.create!(asset_pair:, iso8601_duration:, range_position: 102, interval: 25, value: 1)
    SmoothedMovingAverage.create!(asset_pair:, iso8601_duration:, range_position: 102, interval: 28, value: 1)

    Ohlc.create!(asset_pair:, iso8601_duration:, range_position: 100, high: 1, low: 1, open: 1, close: 1, volume: 1)

    SmoothedMovingAverage.create!(asset_pair:, iso8601_duration:, range_position: 100, interval: 16, value: 1)
    SmoothedMovingAverage.create!(asset_pair:, iso8601_duration:, range_position: 100, interval: 19, value: 1)
    SmoothedMovingAverage.create!(asset_pair:, iso8601_duration:, range_position: 100, interval: 25, value: 1)
    SmoothedMovingAverage.create!(asset_pair:, iso8601_duration:, range_position: 100, interval: 28, value: 1)

    Ohlc.create!(asset_pair:, iso8601_duration:, range_position: 101, high: 1, low: 1, open: 1, close: 1, volume: 1)

    SmoothedMovingAverage.create!(asset_pair:, iso8601_duration:, range_position: 101, interval: 16, value: 1)
    SmoothedMovingAverage.create!(asset_pair:, iso8601_duration:, range_position: 101, interval: 19, value: 1)
    SmoothedMovingAverage.create!(asset_pair:, iso8601_duration:, range_position: 101, interval: 25, value: 1)
    SmoothedMovingAverage.create!(asset_pair:, iso8601_duration:, range_position: 101, interval: 28, value: 1)

    query = SmoothedTrend::UnprocessedSmmasQuery.new(asset_pair:, duration:).call

    assert_equal [100, 101, 102], query.map(&:range_position)
  end

  test 'filters by asset_pair correctly' do
    atomusd = asset_pairs(:atomusd)
    btcusd = asset_pairs(:btcusd)
    duration = 1.day
    iso8601_duration = duration.iso8601

    Ohlc.create!(asset_pair: atomusd, iso8601_duration:, range_position: 100,
                 high: 1, low: 1, open: 1, close: 1, volume: 1)

    SmoothedMovingAverage.create!(asset_pair: atomusd, iso8601_duration:, range_position: 100, interval: 16, value: 1)
    SmoothedMovingAverage.create!(asset_pair: atomusd, iso8601_duration:, range_position: 100, interval: 19, value: 1)
    SmoothedMovingAverage.create!(asset_pair: atomusd, iso8601_duration:, range_position: 100, interval: 25, value: 1)
    SmoothedMovingAverage.create!(asset_pair: atomusd, iso8601_duration:, range_position: 100, interval: 28, value: 1)

    Ohlc.create!(asset_pair: btcusd, iso8601_duration:, range_position: 100,
                 high: 1, low: 1, open: 1, close: 1, volume: 1)

    SmoothedMovingAverage.create!(asset_pair: btcusd, iso8601_duration:, range_position: 100, interval: 16, value: 1)
    SmoothedMovingAverage.create!(asset_pair: btcusd, iso8601_duration:, range_position: 100, interval: 19, value: 1)
    SmoothedMovingAverage.create!(asset_pair: btcusd, iso8601_duration:, range_position: 100, interval: 25, value: 1)
    SmoothedMovingAverage.create!(asset_pair: btcusd, iso8601_duration:, range_position: 100, interval: 28, value: 1)

    query = SmoothedTrend::UnprocessedSmmasQuery.new(asset_pair: atomusd, duration:).call

    assert_equal 1, query.count
    assert_equal atomusd.id, query.first.asset_pair_id
  end

  test 'filters by duration correctly' do
    asset_pair = asset_pairs(:atomusd)

    Ohlc.create!(asset_pair:, iso8601_duration: 'P1D', range_position: 100,
                 high: 1, low: 1, open: 1, close: 1, volume: 1)

    SmoothedMovingAverage.create!(asset_pair:, iso8601_duration: 'P1D', range_position: 100, interval: 16, value: 1)
    SmoothedMovingAverage.create!(asset_pair:, iso8601_duration: 'P1D', range_position: 100, interval: 19, value: 1)
    SmoothedMovingAverage.create!(asset_pair:, iso8601_duration: 'P1D', range_position: 100, interval: 25, value: 1)
    SmoothedMovingAverage.create!(asset_pair:, iso8601_duration: 'P1D', range_position: 100, interval: 28, value: 1)

    Ohlc.create!(asset_pair:, iso8601_duration: 'P2D', range_position: 100,
                 high: 1, low: 1, open: 1, close: 1, volume: 1)

    SmoothedMovingAverage.create!(asset_pair:, iso8601_duration: 'P2D', range_position: 100, interval: 16, value: 1)
    SmoothedMovingAverage.create!(asset_pair:, iso8601_duration: 'P2D', range_position: 100, interval: 19, value: 1)
    SmoothedMovingAverage.create!(asset_pair:, iso8601_duration: 'P2D', range_position: 100, interval: 25, value: 1)
    SmoothedMovingAverage.create!(asset_pair:, iso8601_duration: 'P2D', range_position: 100, interval: 28, value: 1)

    query = SmoothedTrend::UnprocessedSmmasQuery.new(asset_pair:, duration: 1.day).call

    assert_equal 1, query.count
    assert_equal 1.day.iso8601, 'P1D'
  end

  test 'returned data includes all 4 interval values accessible' do
    asset_pair = asset_pairs(:atomusd)
    duration = 1.day
    iso8601_duration = duration.iso8601

    Ohlc.create!(asset_pair:, iso8601_duration:, range_position: 100, high: 1, low: 1, open: 1, close: 1, volume: 1)

    SmoothedMovingAverage.create!(asset_pair:, iso8601_duration:, range_position: 100, interval: 16, value: 1)
    SmoothedMovingAverage.create!(asset_pair:, iso8601_duration:, range_position: 100, interval: 19, value: 2)
    SmoothedMovingAverage.create!(asset_pair:, iso8601_duration:, range_position: 100, interval: 25, value: 3)
    SmoothedMovingAverage.create!(asset_pair:, iso8601_duration:, range_position: 100, interval: 28, value: 4)

    result = SmoothedTrend::UnprocessedSmmasQuery.new(asset_pair:, duration:).call.first

    assert_equal 1, result.fast_value
    assert_equal 2, result.medium_fast_value
    assert_equal 3, result.medium_slow_value
    assert_equal 4, result.slow_value
  end

  test 'supports in_batches for processing large result sets' do
    asset_pair = asset_pairs(:atomusd)
    duration = 1.day
    iso8601_duration = duration.iso8601

    # Create multiple records to test batching
    (100..105).each do |position|
      Ohlc.create!(asset_pair:, iso8601_duration:, range_position: position,
                   high: 1, low: 1, open: 1, close: 1, volume: 1)

      SmoothedMovingAverage.create!(asset_pair:, iso8601_duration:, range_position: position, interval: 16, value: 1.0)
      SmoothedMovingAverage.create!(asset_pair:, iso8601_duration:, range_position: position, interval: 19, value: 2.0)
      SmoothedMovingAverage.create!(asset_pair:, iso8601_duration:, range_position: position, interval: 25, value: 3.0)
      SmoothedMovingAverage.create!(asset_pair:, iso8601_duration:, range_position: position, interval: 28, value: 4.0)
    end

    query = SmoothedTrend::UnprocessedSmmasQuery.new(asset_pair:, duration:).call

    # Should not raise an error
    batch_count = 0
    positions = []

    query.in_batches(of: 2) do |batch|
      batch_count += 1
      positions.concat(batch.pluck(:range_position))
    end

    assert_equal 6, query.count
    assert_equal 3, batch_count # 6 records / 2 per batch = 3 batches
    assert_equal [100, 101, 102, 103, 104, 105], positions.sort
  end
end
