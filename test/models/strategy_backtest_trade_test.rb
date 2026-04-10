# frozen_string_literal: true

require 'test_helper'

class StrategyBacktestTradeTest < ActiveSupport::TestCase
  test '#value returns price times volume' do
    trade = StrategyBacktestTrade.new(price: 102, volume: 50)

    assert_equal 5100, trade.value
  end

  test 'buy and sell action enum' do
    buy_trade  = StrategyBacktestTrade.new(action: 'buy')
    sell_trade = StrategyBacktestTrade.new(action: 'sell')

    assert buy_trade.buy?
    assert sell_trade.sell?
  end
end
