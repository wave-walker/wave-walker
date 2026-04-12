# frozen_string_literal: true

require 'test_helper'

class CreateSmoothedMovingAveragesServiceTest < ActiveSupport::TestCase
  test '#call, creates SMMAs for all intervals when sufficient data exists' do
    asset_pair = asset_pairs(:atomusd)
    intervals = [16, 28]

    # Create 30 OHLCs with enough data for all intervals
    ohlcs = (0...30).map do |i|
      Ohlc.create!(
        asset_pair: asset_pair,
        duration: 1.day,
        range_position: i,
        open: i + 10.0,
        high: i + 11.0,
        low: i + 9.0,
        close: i + 10.0,
        volume: 1000
      )
    end

    assert_difference 'SmoothedMovingAverage.count', 2 do
      CreateSmoothedMovingAveragesService.call([ohlcs.last], intervals)
    end

    intervals.each do |interval|
      smma = SmoothedMovingAverage.find_by(
        asset_pair_id: asset_pair.id,
        iso8601_duration: 'P1D',
        range_position: 29,
        interval: interval
      )
      assert smma, "Expected SMMA for interval #{interval} to exist"
    end
  end

  test '#call, does not create SMMAs when insufficient previous OHLCs' do
    asset_pair = asset_pairs(:atomusd)
    intervals = [16, 20]

    # Only create a few OHLCs - not enough for interval 20
    ohlcs = (0...10).map do |i|
      Ohlc.create!(
        asset_pair: asset_pair,
        duration: 1.day,
        range_position: i,
        open: i + 10.0,
        high: i + 11.0,
        low: i + 9.0,
        close: i + 10.0,
        volume: 1000
      )
    end

    assert_no_changes 'SmoothedMovingAverage.count' do
      CreateSmoothedMovingAveragesService.call([ohlcs.last], intervals)
    end
  end

  test '#call, creates SMMAs for multiple OHLCs in batch' do
    asset_pair = asset_pairs(:atomusd)
    intervals = [10, 15]

    # Create 35 OHLCs
    ohlcs = (0...35).map do |i|
      Ohlc.create!(
        asset_pair: asset_pair,
        duration: 1.day,
        range_position: i,
        open: i + 10.0,
        high: i + 11.0,
        low: i + 9.0,
        close: i + 10.0,
        volume: 1000
      )
    end

    # Process last 5 OHLCs - should create 2 intervals × 5 OHLCs = 10 SMMAs
    target_ohlcs = ohlcs[30..34]

    assert_difference 'SmoothedMovingAverage.count', 10 do
      CreateSmoothedMovingAveragesService.call(target_ohlcs, intervals)
    end
  end

  test '#call, uses cache for sequential calculation within batch' do
    asset_pair = asset_pairs(:atomusd)
    intervals = [8]

    # Create initial 29 OHLCs and their SMMAs
    initial_ohlcs = (0...29).map do |i|
      Ohlc.create!(
        asset_pair: asset_pair,
        duration: 1.day,
        range_position: i,
        open: i + 10.0,
        high: i + 11.0,
        low: i + 9.0,
        close: i + 10.0,
        volume: 1000
      )
    end

    # Create SMMA for the last initial OHLC (position 28)
    CreateSmoothedMovingAveragesService.call([initial_ohlcs.last], intervals)

    # Get the reference value
    reference_smma = SmoothedMovingAverage.find_by!(
      asset_pair_id: asset_pair.id,
      iso8601_duration: 'P1D',
      range_position: 28,
      interval: 8
    )

    # Create 2 more OHLCs
    ohlc_29 = Ohlc.create!(
      asset_pair: asset_pair,
      duration: 1.day,
      range_position: 29,
      open: 39.0,
      high: 40.0,
      low: 38.0,
      close: 39.0,
      volume: 1000
    )

    ohlc_30 = Ohlc.create!(
      asset_pair: asset_pair,
      duration: 1.day,
      range_position: 30,
      open: 40.0,
      high: 41.0,
      low: 39.0,
      close: 40.0,
      volume: 1000
    )

    # Process both new OHLCs
    CreateSmoothedMovingAveragesService.call([ohlc_29, ohlc_30], intervals)

    # Verify ohlc_30's SMMA uses ohlc_29's SMMA (sequential within batch)
    smma_29 = SmoothedMovingAverage.find_by!(
      asset_pair_id: asset_pair.id,
      iso8601_duration: 'P1D',
      range_position: 29,
      interval: 8
    )

    smma_30 = SmoothedMovingAverage.find_by!(
      asset_pair_id: asset_pair.id,
      iso8601_duration: 'P1D',
      range_position: 30,
      interval: 8
    )

    # Calculate expected: ((smma_29 * 7) + hl2_30) / 8
    hl2_30 = (ohlc_30.high + ohlc_30.low) / 2
    expected = ((smma_29.value * 7) + hl2_30) / 8
    expected = expected.round(asset_pair.cost_decimals)

    assert_in_delta smma_30.value, expected, 0.00001
  end

  test '#call, upserts and overrides existing SMMAs' do
    asset_pair = asset_pairs(:atomusd)
    intervals = [5]

    # Create 5 prior OHLCs so we have data for SMA
    (0...5).each do |i|
      Ohlc.create!(
        asset_pair: asset_pair,
        duration: 1.day,
        range_position: i,
        open: 10.0,
        high: 12.0,
        low: 8.0,
        close: 10.0,
        volume: 1000
      )
    end

    ohlc = Ohlc.create!(
      asset_pair: asset_pair,
      duration: 1.day,
      range_position: 5,
      open: 10.0,
      high: 12.0,
      low: 8.0,
      close: 10.0,
      volume: 1000
    )

    # Pre-create a SMMA with a different value
    SmoothedMovingAverage.create!(
      asset_pair_id: asset_pair.id,
      iso8601_duration: 'P1D',
      range_position: 5,
      interval: 5,
      value: 999.0
    )

    # Call service - should upsert and override
    CreateSmoothedMovingAveragesService.call([ohlc], intervals)

    smma = SmoothedMovingAverage.find_by!(
      asset_pair_id: asset_pair.id,
      iso8601_duration: 'P1D',
      range_position: 5,
      interval: 5
    )

    # Value should be updated to 10.0 (hl2 of prior OHLCs and current), not 999.0
    assert_in_delta smma.value, 10.0, 0.1
    assert_not_equal smma.value, 999.0
  end
end
