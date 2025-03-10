# frozen_string_literal: true

require 'test_helper'

class BacktestJobTest < ActiveJob::TestCase
  test '#perform, execute a backtest for batch of trends' do
    backtest = backtests(:atom)

    SmoothedTrendService.call(ohlcs(:atom20230101))
    SmoothedTrendService.call(ohlcs(:atom20230102))

    smoothed_trends = backtest.new_smoothed_trends

    BacktestService.expects(:call).with(backtest:, smoothed_trends:)

    BacktestJob.perform_now(backtest)
  end

  test '#perform, dose nothing when no trends are generated' do
    backtest = backtests(:atom)

    assert_no_changes 'backtest.reload.attributes' do
      BacktestJob.perform_now(backtest)
    end
  end

  test '#concurrency_key, is unique for asset pair and duration' do
    backtest = backtests(:atom)
    job = BacktestJob.perform_later(backtest)

    assert_equal 'BacktestJob/Backtest/1/P1D', job.concurrency_key
  end
end
