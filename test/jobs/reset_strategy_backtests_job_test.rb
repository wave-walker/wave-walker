# frozen_string_literal: true

require 'test_helper'

class ResetStrategyBacktestsJobTest < ActiveJob::TestCase
  test '#perform, resets all strategy_backtests to BACKTEST_FUND' do
    strategy_backtest = strategy_backtests(:atom_daily)
    strategy_backtest.update!(usd_volume: 0, current_value: 0)

    ResetStrategyBacktestsJob.perform_now

    assert_equal Backtest::BACKTEST_FUND, strategy_backtest.reload.usd_volume
  end
end
