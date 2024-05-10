# frozen_string_literal: true

require 'test_helper'

module Scheduler
  class BacktestJobTest < ActiveJob::TestCase
    test 'enqueus a backtest for each asset' do
      atom_backtest = backtests(:atom)
      btc_backtest = Backtest.create!(
        asset_pair: asset_pairs(:btcusd),
        iso8601_duration: 'PT1H',
        usd_quantity: 1000
      )

      BacktestSchedulerJob.perform_now

      assert_enqueued_with(job: BacktestJob, args: [atom_backtest])
      assert_enqueued_with(job: BacktestJob, args: [btc_backtest])
    end
  end
end
