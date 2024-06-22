# frozen_string_literal: true

require 'test_helper'

class BacktestTradeBuilderTest < ActiveSupport::TestCase
  test 'simulates purchase of tokens at close with fee and slippage' do
    ohlc = ohlcs(:atom20230101)
    ohlc.close = 100.0
    trade_type = :buy
    current_quantity = 5000.0

    assert_equal BacktestTradeBuilder.build(ohlc:, trade_type:, current_quantity:), {
      asset_pair_id: 1,
      iso8601_duration: 'P1D',
      fee: 100,
      quantity: 48.039216, # token
      price: 102,
      trade_type: :buy,
      range_position: 19_358
    }
  end

  test 'simulates selling of tokens at close with fee and slippage' do
    ohlc = ohlcs(:atom20230101)
    ohlc.close = 50.0
    trade_type = :sell
    current_quantity = 25.0

    assert_equal BacktestTradeBuilder.build(ohlc:, trade_type:, current_quantity:), {
      asset_pair_id: 1,
      iso8601_duration: 'P1D',
      fee: 24.5,
      quantity: 1200.5, # usd
      price: 49,
      trade_type: :sell,
      range_position: 19_358
    }
  end
end
