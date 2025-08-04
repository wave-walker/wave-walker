# frozen_string_literal: true

require 'test_helper'

class ResetBacktestsJobTest < ActiveJob::TestCase
  test 'reset backtests for assets' do
    atom_backtest = backtests(:atom)
    atom_backtest.update!(usd_volume: 0)

    assert_difference 'atom_backtest.reload.usd_volume', Backtest::BACKTEST_FUND do
      ResetBacktestsJob.perform_now
    end
  end
end
