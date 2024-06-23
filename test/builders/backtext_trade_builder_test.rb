# frozen_string_literal: true

require 'test_helper'

class BacktestTradeBuilderTest < ActiveSupport::TestCase
  test 'simulates purchase of tokens at close with fee and slippage' do
    ohlc = ohlcs(:atom20230101)
    ohlc.close = 100.0
    action = :buy
    backtest = backtests(:atom)
    backtest.usd_volume = 5000.0
    backtest.token_volume = 0

    assert_equal BacktestTradeBuilder.build(ohlc:, action:, backtest:), {
      asset_pair_id: 1,
      iso8601_duration: 'P1D',
      fee: 100,
      volume: 48.039216,
      price: 102,
      action: :buy,
      range_position: 19_358
    }
  end

  test 'simulates selling of tokens at close with fee and slippage' do
    ohlc = ohlcs(:atom20230101)
    ohlc.close = 150.0
    action = :sell
    backtest = backtests(:atom)
    backtest.usd_volume = 0
    backtest.token_volume = 25.0

    assert_equal BacktestTradeBuilder.build(ohlc:, action:, backtest:), {
      asset_pair_id: 1,
      iso8601_duration: 'P1D',
      fee: 73.5,
      volume: 24.5,
      price: 147,
      action: :sell,
      range_position: 19_358
    }
  end
end
