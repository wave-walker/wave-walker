# frozen_string_literal: true

require 'test_helper'

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
end
