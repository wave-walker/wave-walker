# frozen_string_literal: true

require 'test_helper'

module Scheduler
  class StrategyBacktestJobTest < ActiveJob::TestCase
    test '#perform, enqueues StrategyBacktestJob for each importing strategy_backtest' do
      # atom_daily strategy_backtest belongs to atomusd which has importing: true
      assert_enqueued_with(job: StrategyBacktestJob) do
        StrategyBacktestSchedulerJob.perform_now
      end
    end

    test '#perform, does not enqueue for non-importing asset pairs' do
      # btcusd has importing: false; there are no strategy_backtests for it in fixtures
      assert_no_enqueued_jobs only: StrategyBacktestJob do
        # Use a fresh strategy_backtest belonging to non-importing btcusd
        strategy = strategies(:default)
        StrategyBacktest.create!(
          strategy:,
          asset_pair: asset_pairs(:btcusd),
          duration: 1.day
        )
        # Wipe the atomusd one so only btcusd is present
        StrategyBacktest.where(asset_pair: asset_pairs(:atomusd)).destroy_all

        StrategyBacktestSchedulerJob.perform_now
      end
    end
  end
end
