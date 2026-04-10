# frozen_string_literal: true

require 'test_helper'

class StrategyTradeBuilderTest < ActiveSupport::TestCase
  test 'simulates purchase of tokens at close with configurable slippage and fee' do
    ohlc = ohlcs(:atom20230101)
    ohlc.close = 100.0
    strategy_backtest = StrategyBacktest.new(
      strategy: strategies(:default),
      asset_pair: asset_pairs(:atomusd),
      usd_volume: 5000.0,
      token_volume: 0
    )

    # slippage=0.02, fee=0.02 (same as BacktestTradeBuilder defaults)
    result = StrategyTradeBuilder.build(ohlc:, strategy_backtest:, action: :buy, slippage: 0.02, fee: 0.02)

    assert_equal :buy,       result[:action]
    assert_equal 102,        result[:price]
    assert_equal 48.039216,  result[:volume]
    assert_equal 100,        result[:fee]
    assert_equal 1,          result[:asset_pair_id]
    assert_equal 'P1D',      result[:iso8601_duration]
    assert_equal ohlc.range_position, result[:range_position]
  end

  test 'simulates selling of tokens at close with configurable slippage and fee' do
    ohlc = ohlcs(:atom20230101)
    ohlc.close = 150.0
    strategy_backtest = StrategyBacktest.new(
      strategy: strategies(:default),
      asset_pair: asset_pairs(:atomusd),
      usd_volume: 0,
      token_volume: 25.0
    )

    result = StrategyTradeBuilder.build(ohlc:, strategy_backtest:, action: :sell, slippage: 0.02, fee: 0.02)

    assert_equal :sell,   result[:action]
    assert_equal 147,     result[:price]
    assert_equal 24.5,    result[:volume]
    assert_equal 73.5,    result[:fee]
  end

  test 'applies different slippage and fee when configured' do
    ohlc = ohlcs(:atom20230101)
    ohlc.close = 100.0
    strategy_backtest = StrategyBacktest.new(
      strategy: strategies(:default),
      asset_pair: asset_pairs(:atomusd),
      usd_volume: 1000.0,
      token_volume: 0
    )

    result = StrategyTradeBuilder.build(ohlc:, strategy_backtest:, action: :buy, slippage: 0.01, fee: 0.01)

    assert_equal 101,       result[:price] # 100 * (1 + 0.01)
    assert_in_delta 9.801,  result[:volume], 0.001  # (1000/101) * (1-0.01)
    assert_in_delta 10.0,   result[:fee], 0.01      # (1000/101) * 101 * 0.01
  end
end
