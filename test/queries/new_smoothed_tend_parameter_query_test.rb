# frozen_string_literal: true

require 'test_helper'

class NewSmoothedTendParameterQueryTest < ActiveSupport::TestCase
  def create_smmas(asset_pair:, iso8601_duration:, range_position:, fast:, medium_fast:, medium_slow:, slow:)
    Ohlc.create!(asset_pair:, iso8601_duration:, range_position:, high: 1, low: 1, open: 1, close: 1, volume: 1)
    SmoothedMovingAverage.create!(asset_pair:, iso8601_duration:, range_position:, interval: 16, value: fast)
    SmoothedMovingAverage.create!(asset_pair:, iso8601_duration:, range_position:, interval: 19, value: medium_fast)
    SmoothedMovingAverage.create!(asset_pair:, iso8601_duration:, range_position:, interval: 25, value: medium_slow)
    SmoothedMovingAverage.create!(asset_pair:, iso8601_duration:, range_position:, interval: 28, value: slow)
  end

  def collect_params(asset_pair:, duration:)
    results = []
    NewSmoothedTendParameterQuery.new(asset_pair:, duration:).in_batches do |batch|
      results.concat(batch)
    end
    results
  end

  test 'yields nothing when no SMMAs exist' do
    asset_pair = asset_pairs(:atomusd)

    results = collect_params(asset_pair:, duration: 1.day)

    assert_empty results
  end

  test 'yields nothing when only some intervals exist' do
    asset_pair = asset_pairs(:atomusd)
    iso8601_duration = 1.day.iso8601

    Ohlc.create!(asset_pair:, iso8601_duration:, range_position: 100, high: 1, low: 1, open: 1, close: 1, volume: 1)
    SmoothedMovingAverage.create!(asset_pair:, iso8601_duration:, range_position: 100, interval: 16, value: 1)
    SmoothedMovingAverage.create!(asset_pair:, iso8601_duration:, range_position: 100, interval: 19, value: 1)
    SmoothedMovingAverage.create!(asset_pair:, iso8601_duration:, range_position: 100, interval: 25, value: 1)
    # interval 28 missing

    results = collect_params(asset_pair:, duration: 1.day)

    assert_empty results
  end

  test 'yields params when all 4 intervals exist' do
    asset_pair = asset_pairs(:atomusd)
    iso8601_duration = 1.day.iso8601

    create_smmas(asset_pair:, iso8601_duration:, range_position: 100,
                 fast: 1, medium_fast: 2, medium_slow: 3, slow: 4)

    results = collect_params(asset_pair:, duration: 1.day)

    assert_equal 1, results.size
  end

  test 'skips positions already covered by an existing SmoothedTrend' do
    asset_pair = asset_pairs(:atomusd)
    iso8601_duration = 1.day.iso8601

    create_smmas(asset_pair:, iso8601_duration:, range_position: 100,
                 fast: 10, medium_fast: 9, medium_slow: 8, slow: 7)

    SmoothedTrend.create!(asset_pair:, iso8601_duration:, range_position: 100,
                          fast_smma: 10, slow_smma: 7, trend: 'bullish', flip: false)

    results = collect_params(asset_pair:, duration: 1.day)

    assert_empty results
  end

  test 'only returns positions after the latest existing SmoothedTrend' do
    asset_pair = asset_pairs(:atomusd)
    iso8601_duration = 1.day.iso8601

    create_smmas(asset_pair:, iso8601_duration:, range_position: 100,
                 fast: 10, medium_fast: 9, medium_slow: 8, slow: 7)
    create_smmas(asset_pair:, iso8601_duration:, range_position: 101,
                 fast: 10, medium_fast: 9, medium_slow: 8, slow: 7)

    SmoothedTrend.create!(asset_pair:, iso8601_duration:, range_position: 100,
                          fast_smma: 10, slow_smma: 7, trend: 'bullish', flip: false)

    results = collect_params(asset_pair:, duration: 1.day)

    assert_equal 1, results.size
    assert_equal 101, results.first[:range_position]
  end

  test 'yields params in ascending range_position order' do
    asset_pair = asset_pairs(:atomusd)
    iso8601_duration = 1.day.iso8601

    create_smmas(asset_pair:, iso8601_duration:, range_position: 102,
                 fast: 10, medium_fast: 9, medium_slow: 8, slow: 7)
    create_smmas(asset_pair:, iso8601_duration:, range_position: 100,
                 fast: 10, medium_fast: 9, medium_slow: 8, slow: 7)
    create_smmas(asset_pair:, iso8601_duration:, range_position: 101,
                 fast: 10, medium_fast: 9, medium_slow: 8, slow: 7)

    results = collect_params(asset_pair:, duration: 1.day)

    assert_equal([100, 101, 102], results.pluck(:range_position))
  end

  test 'params include required keys' do
    asset_pair = asset_pairs(:atomusd)
    iso8601_duration = 1.day.iso8601

    create_smmas(asset_pair:, iso8601_duration:, range_position: 100,
                 fast: 10, medium_fast: 9, medium_slow: 8, slow: 7)

    result = collect_params(asset_pair:, duration: 1.day).first

    assert_equal 100, result[:range_position]
    assert_equal asset_pair.id, result[:asset_pair_id]
    assert_equal iso8601_duration, result[:iso8601_duration]
    assert_includes %i[bullish bearish neutral], result[:trend]
    assert_includes [true, false], result[:flip]
  end

  test 'calculates bullish trend when fast > slow and no crossover condition' do
    asset_pair = asset_pairs(:atomusd)
    iso8601_duration = 1.day.iso8601

    # fast > medium_fast > medium_slow > slow => bullish
    create_smmas(asset_pair:, iso8601_duration:, range_position: 100,
                 fast: 10, medium_fast: 9, medium_slow: 8, slow: 7)

    result = collect_params(asset_pair:, duration: 1.day).first

    assert_equal :bullish, result[:trend]
  end

  test 'calculates bearish trend when fast < slow and no crossover condition' do
    asset_pair = asset_pairs(:atomusd)
    iso8601_duration = 1.day.iso8601

    # fast <= slow, fast >= medium_fast, medium_slow >= slow => bearish
    create_smmas(asset_pair:, iso8601_duration:, range_position: 100,
                 fast: 7, medium_fast: 7, medium_slow: 10, slow: 10)

    result = collect_params(asset_pair:, duration: 1.day).first

    assert_equal :bearish, result[:trend]
  end

  test 'calculates neutral trend when fast < medium_fast' do
    asset_pair = asset_pairs(:atomusd)
    iso8601_duration = 1.day.iso8601

    # fast < medium_fast triggers neutral
    create_smmas(asset_pair:, iso8601_duration:, range_position: 100,
                 fast: 5, medium_fast: 9, medium_slow: 8, slow: 7)

    result = collect_params(asset_pair:, duration: 1.day).first

    assert_equal :neutral, result[:trend]
  end

  test 'calculates neutral trend when medium_slow < slow' do
    asset_pair = asset_pairs(:atomusd)
    iso8601_duration = 1.day.iso8601

    # medium_slow < slow triggers neutral
    create_smmas(asset_pair:, iso8601_duration:, range_position: 100,
                 fast: 10, medium_fast: 9, medium_slow: 6, slow: 7)

    result = collect_params(asset_pair:, duration: 1.day).first

    assert_equal :neutral, result[:trend]
  end

  test 'flip is false for the first result' do
    asset_pair = asset_pairs(:atomusd)
    iso8601_duration = 1.day.iso8601

    create_smmas(asset_pair:, iso8601_duration:, range_position: 100,
                 fast: 10, medium_fast: 9, medium_slow: 8, slow: 7)

    result = collect_params(asset_pair:, duration: 1.day).first

    assert_equal false, result[:flip]
  end

  test 'flip is false when trend is the same as previous' do
    asset_pair = asset_pairs(:atomusd)
    iso8601_duration = 1.day.iso8601

    create_smmas(asset_pair:, iso8601_duration:, range_position: 100,
                 fast: 10, medium_fast: 9, medium_slow: 8, slow: 7)
    create_smmas(asset_pair:, iso8601_duration:, range_position: 101,
                 fast: 11, medium_fast: 10, medium_slow: 9, slow: 8)

    results = collect_params(asset_pair:, duration: 1.day)

    assert_equal :bullish, results[0][:trend]
    assert_equal :bullish, results[1][:trend]
    assert_equal false, results[1][:flip]
  end

  test 'flip is true when trend changes from one position to the next' do
    asset_pair = asset_pairs(:atomusd)
    iso8601_duration = 1.day.iso8601

    # position 100 => bullish (fast > slow, no crossover)
    create_smmas(asset_pair:, iso8601_duration:, range_position: 100,
                 fast: 10, medium_fast: 9, medium_slow: 8, slow: 7)
    # position 101 => neutral (fast < medium_fast)
    create_smmas(asset_pair:, iso8601_duration:, range_position: 101,
                 fast: 5, medium_fast: 9, medium_slow: 8, slow: 7)

    results = collect_params(asset_pair:, duration: 1.day)

    assert_equal :bullish, results[0][:trend]
    assert_equal :neutral, results[1][:trend]
    assert_equal true, results[1][:flip]
  end

  test 'filters by asset_pair correctly' do
    atomusd = asset_pairs(:atomusd)
    btcusd = asset_pairs(:btcusd)
    iso8601_duration = 1.day.iso8601

    create_smmas(asset_pair: atomusd, iso8601_duration:, range_position: 100,
                 fast: 10, medium_fast: 9, medium_slow: 8, slow: 7)
    create_smmas(asset_pair: btcusd, iso8601_duration:, range_position: 100,
                 fast: 10, medium_fast: 9, medium_slow: 8, slow: 7)

    results = collect_params(asset_pair: atomusd, duration: 1.day)

    assert_equal 1, results.size
    assert_equal atomusd.id, results.first[:asset_pair_id]
  end

  test 'filters by duration correctly' do
    asset_pair = asset_pairs(:atomusd)

    create_smmas(asset_pair:, iso8601_duration: 'P1D', range_position: 100,
                 fast: 10, medium_fast: 9, medium_slow: 8, slow: 7)
    create_smmas(asset_pair:, iso8601_duration: 'P2D', range_position: 100,
                 fast: 10, medium_fast: 9, medium_slow: 8, slow: 7)

    results = collect_params(asset_pair:, duration: 2.days)

    assert_equal 1, results.size
    assert_equal 'P2D', results.first[:iso8601_duration]
  end
end
