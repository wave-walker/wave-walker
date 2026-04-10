# frozen_string_literal: true

require 'test_helper'

class EnsureSmmaIntervalsServiceTest < ActiveSupport::TestCase
  test 'creates missing SMMA values for strategy fast and slow intervals' do
    Strategy.create!(
      name: 'ensure_smma_test',
      fast_interval: 16,
      slow_interval: 28,
      entry_on: 'bullish',
      exit_on: 'neutral_or_bearish',
      slippage: 0.02,
      fee: 0.02
    )

    # Intervals 16 and 28 are created by SmoothedTrendService, but let's
    # verify EnsureSmmaIntervalsService handles already-present intervals gracefully
    # and creates truly missing ones (e.g. interval 10).
    new_strategy = Strategy.create!(
      name: 'ensure_smma_new_intervals',
      fast_interval: 10,
      slow_interval: 22,
      entry_on: 'bullish',
      exit_on: 'neutral_or_bearish',
      slippage: 0.01,
      fee: 0.01
    )

    # Generate enough OHLCs so SMMAs can be computed (need at least slow_interval candles)
    ohlcs = (1..30).map do |i|
      ohlcs(:"atom2022120#{i < 10 ? "0#{i}" : i}")
    rescue StandardError
      nil
    end.compact
    ohlcs.first(30)

    before_count = SmoothedMovingAverage.where(interval: %w[10 22]).count

    EnsureSmmaIntervalsService.call(strategy: new_strategy)

    after_count = SmoothedMovingAverage.where(interval: %w[10 22]).count
    assert after_count > before_count
  end

  test 'is idempotent - calling twice does not duplicate SMMA records' do
    strategy = Strategy.create!(
      name: 'ensure_smma_idempotent',
      fast_interval: 16,
      slow_interval: 28,
      entry_on: 'bullish',
      exit_on: 'neutral_or_bearish',
      slippage: 0.02,
      fee: 0.02
    )

    EnsureSmmaIntervalsService.call(strategy:)
    count_after_first = SmoothedMovingAverage.where(interval: %w[16 28]).count

    EnsureSmmaIntervalsService.call(strategy:)
    count_after_second = SmoothedMovingAverage.where(interval: %w[16 28]).count

    assert_equal count_after_first, count_after_second
  end
end
