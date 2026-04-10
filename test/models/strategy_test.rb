# frozen_string_literal: true

require 'test_helper'

class StrategyTest < ActiveSupport::TestCase
  test 'valid with all required attributes' do
    strategy = Strategy.new(
      name: 'Test Strategy',
      fast_interval: 16,
      slow_interval: 28,
      entry_on: 'bullish',
      exit_on: 'neutral_or_bearish',
      slippage: 0.02,
      fee: 0.02
    )

    assert strategy.valid?
  end

  test '#entry_bullish? is true when entry_on is bullish' do
    strategy = Strategy.new(entry_on: 'bullish')

    assert strategy.entry_bullish?
    assert_not strategy.entry_bullish_or_neutral?
  end

  test '#entry_bullish_or_neutral? is true when entry_on is bullish_or_neutral' do
    strategy = Strategy.new(entry_on: 'bullish_or_neutral')

    assert strategy.entry_bullish_or_neutral?
    assert_not strategy.entry_bullish?
  end

  test '#exit_neutral_or_bearish? is true when exit_on is neutral_or_bearish' do
    strategy = Strategy.new(exit_on: 'neutral_or_bearish')

    assert strategy.exit_neutral_or_bearish?
    assert_not strategy.exit_bearish_only?
  end

  test '#exit_bearish_only? is true when exit_on is bearish_only' do
    strategy = Strategy.new(exit_on: 'bearish_only')

    assert strategy.exit_bearish_only?
    assert_not strategy.exit_neutral_or_bearish?
  end

  test 'has_many strategy_backtests' do
    strategy = strategies(:default)

    assert_respond_to strategy, :strategy_backtests
  end
end
