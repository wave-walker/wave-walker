# frozen_string_literal: true

require 'test_helper'

module SmoothedTrend
  class SmmaValuesTest < ActiveSupport::TestCase
    # Helper to create stub SMMA objects
    StubSmma = Struct.new(:interval, :value, keyword_init: true)

    test 'initializes with all four SMMA values' do
      smma_values = SmoothedTrend::SmmaValues.new(
        fast: 100.0,
        medium_fast: 98.0,
        medium_slow: 96.0,
        slow: 94.0
      )

      assert_equal 100.0, smma_values.fast
      assert_equal 98.0, smma_values.medium_fast
      assert_equal 96.0, smma_values.medium_slow
      assert_equal 94.0, smma_values.slow
    end

    test '.from_array creates SmmaValues from complete SMMA set' do
      # Create stub SMMA objects with interval and value methods
      fast_smma = StubSmma.new(interval: SmoothedTrend::SMMA_FAST_INTERVAL, value: 100.0)
      medium_fast_smma = StubSmma.new(interval: SmoothedTrend::SMMA_MEDIUM_FAST_INTERVAL, value: 98.0)
      medium_slow_smma = StubSmma.new(interval: SmoothedTrend::SMMA_MEDIUM_SLOW_INTERVAL, value: 96.0)
      slow_smma = StubSmma.new(interval: SmoothedTrend::SMMA_SLOW_INTERVAL, value: 94.0)

      smmas = [fast_smma, medium_fast_smma, medium_slow_smma, slow_smma]
      smma_values = SmoothedTrend::SmmaValues.from_array(smmas)

      assert_equal 100.0, smma_values.fast
      assert_equal 98.0, smma_values.medium_fast
      assert_equal 96.0, smma_values.medium_slow
      assert_equal 94.0, smma_values.slow
    end

    test '.from_array handles missing SMMA by setting value to nil' do
      # Create only 3 stub SMMAs (missing the slow one)
      fast_smma = StubSmma.new(interval: SmoothedTrend::SMMA_FAST_INTERVAL, value: 100.0)
      medium_fast_smma = StubSmma.new(interval: SmoothedTrend::SMMA_MEDIUM_FAST_INTERVAL, value: 98.0)
      medium_slow_smma = StubSmma.new(interval: SmoothedTrend::SMMA_MEDIUM_SLOW_INTERVAL, value: 96.0)

      smmas = [fast_smma, medium_fast_smma, medium_slow_smma]
      smma_values = SmoothedTrend::SmmaValues.from_array(smmas)

      assert_equal 100.0, smma_values.fast
      assert_equal 98.0, smma_values.medium_fast
      assert_equal 96.0, smma_values.medium_slow
      assert_nil smma_values.slow
    end

    test '.from_array handles unordered SMMA array' do
      # Create stub SMMAs and put them in the array in random order
      slow_smma = StubSmma.new(interval: SmoothedTrend::SMMA_SLOW_INTERVAL, value: 94.0)
      fast_smma = StubSmma.new(interval: SmoothedTrend::SMMA_FAST_INTERVAL, value: 100.0)
      medium_slow_smma = StubSmma.new(interval: SmoothedTrend::SMMA_MEDIUM_SLOW_INTERVAL, value: 96.0)
      medium_fast_smma = StubSmma.new(interval: SmoothedTrend::SMMA_MEDIUM_FAST_INTERVAL, value: 98.0)

      smmas = [slow_smma, fast_smma, medium_slow_smma, medium_fast_smma]
      smma_values = SmoothedTrend::SmmaValues.from_array(smmas)

      assert_equal 100.0, smma_values.fast
      assert_equal 98.0, smma_values.medium_fast
      assert_equal 96.0, smma_values.medium_slow
      assert_equal 94.0, smma_values.slow
    end

    test '.from_array handles empty array by setting all values to nil' do
      smmas = []
      smma_values = SmoothedTrend::SmmaValues.from_array(smmas)

      assert_nil smma_values.fast
      assert_nil smma_values.medium_fast
      assert_nil smma_values.medium_slow
      assert_nil smma_values.slow
    end

    test '#complete? returns true when all values are present' do
      smma_values = SmoothedTrend::SmmaValues.new(
        fast: 100.0,
        medium_fast: 98.0,
        medium_slow: 96.0,
        slow: 94.0
      )

      assert smma_values.complete?
    end

    test '#complete? returns false when fast value is nil' do
      smma_values = SmoothedTrend::SmmaValues.new(
        fast: nil,
        medium_fast: 98.0,
        medium_slow: 96.0,
        slow: 94.0
      )

      assert_not smma_values.complete?
    end

    test '#complete? returns false when medium_fast value is nil' do
      smma_values = SmoothedTrend::SmmaValues.new(
        fast: 100.0,
        medium_fast: nil,
        medium_slow: 96.0,
        slow: 94.0
      )

      assert_not smma_values.complete?
    end

    test '#complete? returns false when medium_slow value is nil' do
      smma_values = SmoothedTrend::SmmaValues.new(
        fast: 100.0,
        medium_fast: 98.0,
        medium_slow: nil,
        slow: 94.0
      )

      assert_not smma_values.complete?
    end

    test '#complete? returns false when slow value is nil' do
      smma_values = SmoothedTrend::SmmaValues.new(
        fast: 100.0,
        medium_fast: 98.0,
        medium_slow: 96.0,
        slow: nil
      )

      assert_not smma_values.complete?
    end

    test '#complete? returns false when all values are nil' do
      smma_values = SmoothedTrend::SmmaValues.new(
        fast: nil,
        medium_fast: nil,
        medium_slow: nil,
        slow: nil
      )

      assert_not smma_values.complete?
    end

    test '#complete? returns true when values are zero (not nil)' do
      # Edge case: 0 is a valid value, not the same as nil
      smma_values = SmoothedTrend::SmmaValues.new(
        fast: 0.0,
        medium_fast: 0.0,
        medium_slow: 0.0,
        slow: 0.0
      )

      assert smma_values.complete?
    end
  end
end
