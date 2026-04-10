# frozen_string_literal: true

require 'test_helper'

class StrategyBacktestJobTest < ActiveJob::TestCase
  test '#perform, executes a strategy backtest for a batch of trends' do
    strategy_backtest = strategy_backtests(:atom_daily)

    SmoothedTrendService.call(ohlcs(:atom20230101))
    SmoothedTrendService.call(ohlcs(:atom20230102))

    smoothed_trends = strategy_backtest.new_smoothed_trends

    StrategyBacktestService.expects(:call).with(strategy_backtest:, smoothed_trends:)

    StrategyBacktestJob.perform_now(strategy_backtest)
  end

  test '#perform, does nothing when no trends are available' do
    strategy_backtest = strategy_backtests(:atom_daily)

    assert_no_changes 'strategy_backtest.reload.attributes' do
      StrategyBacktestJob.perform_now(strategy_backtest)
    end
  end

  test '#concurrency_key, is unique for strategy and asset pair and duration' do
    strategy_backtest = strategy_backtests(:atom_daily)
    job = StrategyBacktestJob.perform_later(strategy_backtest)

    assert_equal 'StrategyBacktestJob/StrategyBacktest/1/1/P1D', job.concurrency_key
  end
end
