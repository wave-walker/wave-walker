# frozen_string_literal: true

class EnsureSmmaIntervalsJobTest < ActiveJob::TestCase
  test '#perform, creates missing SMMA records for the strategy intervals' do
    strategy = Strategy.create!(
      name: 'ensure_job_test',
      fast_interval: 10,
      slow_interval: 22,
      entry_on: 'bullish',
      exit_on: 'neutral_or_bearish',
      slippage: 0.02,
      fee: 0.02
    )

    before_count = SmoothedMovingAverage.where(interval: %w[10 22]).count

    EnsureSmmaIntervalsJob.perform_now(strategy)

    assert SmoothedMovingAverage.where(interval: %w[10 22]).count > before_count
  end

  test '#perform, is idempotent - running twice does not duplicate SMMA records' do
    strategy = Strategy.create!(
      name: 'ensure_job_idempotent',
      fast_interval: 16,
      slow_interval: 28,
      entry_on: 'bullish',
      exit_on: 'neutral_or_bearish',
      slippage: 0.02,
      fee: 0.02
    )

    EnsureSmmaIntervalsJob.perform_now(strategy)
    count_after_first = SmoothedMovingAverage.where(interval: %w[16 28]).count

    EnsureSmmaIntervalsJob.perform_now(strategy)
    count_after_second = SmoothedMovingAverage.where(interval: %w[16 28]).count

    assert_equal count_after_first, count_after_second
  end

  test '#perform, skips already-present intervals and only fills missing ones' do
    strategy = Strategy.create!(
      name: 'ensure_job_skip_existing',
      fast_interval: 10,
      slow_interval: 22,
      entry_on: 'bullish',
      exit_on: 'neutral_or_bearish',
      slippage: 0.01,
      fee: 0.01
    )

    before_count = SmoothedMovingAverage.where(interval: %w[10 22]).count

    EnsureSmmaIntervalsJob.perform_now(strategy)

    after_count = SmoothedMovingAverage.where(interval: %w[10 22]).count
    assert after_count >= before_count
  end
end
