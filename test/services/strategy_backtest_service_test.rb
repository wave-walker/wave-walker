# frozen_string_literal: true

require 'test_helper'

class StrategyBacktestServiceTest < ActiveSupport::TestCase
  def build_strategy_backtest(strategy:)
    StrategyBacktest.create!(
      strategy:,
      asset_pair: asset_pairs(:atomusd),
      duration: 1.day
    )
  end

  def build_smmas(ohlc, fast_interval:, slow_interval:, fast_value:, slow_value:)
    SmoothedMovingAverage.find_or_create_by!(
      asset_pair_id: ohlc.asset_pair_id,
      iso8601_duration: ohlc.iso8601_duration,
      range_position: ohlc.range_position,
      interval: fast_interval.to_s
    ) { |s| s.value = fast_value }

    SmoothedMovingAverage.find_or_create_by!(
      asset_pair_id: ohlc.asset_pair_id,
      iso8601_duration: ohlc.iso8601_duration,
      range_position: ohlc.range_position,
      interval: slow_interval.to_s
    ) { |s| s.value = slow_value }
  end

  test 'buys on bullish signal when entry_on is bullish' do
    strategy = Strategy.create!(
      name: 'test_buy_bullish',
      fast_interval: 10, slow_interval: 20,
      entry_on: 'bullish', exit_on: 'neutral_or_bearish',
      slippage: 0.02, fee: 0.02
    )
    sb = build_strategy_backtest(strategy:)
    ohlc = ohlcs(:atom20230101)
    ohlc.update!(close: 100)

    # fast > slow => bullish
    build_smmas(ohlc, fast_interval: 10, slow_interval: 20, fast_value: 15, slow_value: 10)
    smoothed_trend = SmoothedTrend.create!(
      asset_pair_id: ohlc.asset_pair_id,
      iso8601_duration: ohlc.iso8601_duration,
      range_position: ohlc.range_position,
      fast_smma: 15, slow_smma: 10,
      trend: :bullish, flip: true,
      ohlc:
    )

    assert_changes 'StrategyBacktestTrade.count', to: 1 do
      StrategyBacktestService.call(strategy_backtest: sb, smoothed_trends: [smoothed_trend])
    end

    trade = StrategyBacktestTrade.last
    assert_equal 'buy', trade.action
  end

  test 'sells on neutral signal when exit_on is neutral_or_bearish' do
    strategy = Strategy.create!(
      name: 'test_sell_neutral',
      fast_interval: 10, slow_interval: 20,
      entry_on: 'bullish', exit_on: 'neutral_or_bearish',
      slippage: 0.02, fee: 0.02
    )
    sb = build_strategy_backtest(strategy:)
    sb.update!(usd_volume: 0, token_volume: 1000)
    ohlc = ohlcs(:atom20230101)
    ohlc.update!(close: 100)

    build_smmas(ohlc, fast_interval: 10, slow_interval: 20, fast_value: 10, slow_value: 15)
    smoothed_trend = SmoothedTrend.create!(
      asset_pair_id: ohlc.asset_pair_id,
      iso8601_duration: ohlc.iso8601_duration,
      range_position: ohlc.range_position,
      fast_smma: 10, slow_smma: 15,
      trend: :neutral, flip: true,
      ohlc:
    )

    assert_changes 'StrategyBacktestTrade.count', to: 1 do
      StrategyBacktestService.call(strategy_backtest: sb, smoothed_trends: [smoothed_trend])
    end

    trade = StrategyBacktestTrade.last
    assert_equal 'sell', trade.action
  end

  test 'holds through neutral when exit_on is bearish_only' do
    strategy = Strategy.create!(
      name: 'test_hold_neutral',
      fast_interval: 10, slow_interval: 20,
      entry_on: 'bullish', exit_on: 'bearish_only',
      slippage: 0.02, fee: 0.02
    )
    sb = build_strategy_backtest(strategy:)
    sb.update!(usd_volume: 0, token_volume: 1000)
    ohlc = ohlcs(:atom20230101)
    ohlc.update!(close: 100)

    build_smmas(ohlc, fast_interval: 10, slow_interval: 20, fast_value: 10, slow_value: 15)
    smoothed_trend = SmoothedTrend.create!(
      asset_pair_id: ohlc.asset_pair_id,
      iso8601_duration: ohlc.iso8601_duration,
      range_position: ohlc.range_position,
      fast_smma: 10, slow_smma: 15,
      trend: :neutral, flip: true,
      ohlc:
    )

    assert_no_changes 'StrategyBacktestTrade.count' do
      StrategyBacktestService.call(strategy_backtest: sb, smoothed_trends: [smoothed_trend])
    end
  end

  test 'sells on bearish when exit_on is bearish_only' do
    strategy = Strategy.create!(
      name: 'test_sell_bearish_only',
      fast_interval: 10, slow_interval: 20,
      entry_on: 'bullish', exit_on: 'bearish_only',
      slippage: 0.02, fee: 0.02
    )
    sb = build_strategy_backtest(strategy:)
    sb.update!(usd_volume: 0, token_volume: 1000)
    ohlc = ohlcs(:atom20230101)
    ohlc.update!(close: 100)

    build_smmas(ohlc, fast_interval: 10, slow_interval: 20, fast_value: 5, slow_value: 15)
    smoothed_trend = SmoothedTrend.create!(
      asset_pair_id: ohlc.asset_pair_id,
      iso8601_duration: ohlc.iso8601_duration,
      range_position: ohlc.range_position,
      fast_smma: 5, slow_smma: 15,
      trend: :bearish, flip: true,
      ohlc:
    )

    assert_changes 'StrategyBacktestTrade.count', to: 1 do
      StrategyBacktestService.call(strategy_backtest: sb, smoothed_trends: [smoothed_trend])
    end

    assert_equal 'sell', StrategyBacktestTrade.last.action
  end

  test 'buys on neutral when entry_on is bullish_or_neutral' do
    strategy = Strategy.create!(
      name: 'test_buy_on_neutral',
      fast_interval: 10, slow_interval: 20,
      entry_on: 'bullish_or_neutral', exit_on: 'bearish_only',
      slippage: 0.02, fee: 0.02
    )
    sb = build_strategy_backtest(strategy:)
    ohlc = ohlcs(:atom20230101)
    ohlc.update!(close: 100)

    build_smmas(ohlc, fast_interval: 10, slow_interval: 20, fast_value: 10, slow_value: 15)
    smoothed_trend = SmoothedTrend.create!(
      asset_pair_id: ohlc.asset_pair_id,
      iso8601_duration: ohlc.iso8601_duration,
      range_position: ohlc.range_position,
      fast_smma: 10, slow_smma: 15,
      trend: :neutral, flip: true,
      ohlc:
    )

    assert_changes 'StrategyBacktestTrade.count', to: 1 do
      StrategyBacktestService.call(strategy_backtest: sb, smoothed_trends: [smoothed_trend])
    end

    assert_equal 'buy', StrategyBacktestTrade.last.action
  end

  test 'skips non-flip candles' do
    strategy = Strategy.create!(
      name: 'test_skip_non_flip',
      fast_interval: 10, slow_interval: 20,
      entry_on: 'bullish', exit_on: 'neutral_or_bearish',
      slippage: 0.02, fee: 0.02
    )
    sb = build_strategy_backtest(strategy:)
    ohlc = ohlcs(:atom20230101)
    ohlc.update!(close: 100)

    build_smmas(ohlc, fast_interval: 10, slow_interval: 20, fast_value: 15, slow_value: 10)
    smoothed_trend = SmoothedTrend.create!(
      asset_pair_id: ohlc.asset_pair_id,
      iso8601_duration: ohlc.iso8601_duration,
      range_position: ohlc.range_position,
      fast_smma: 15, slow_smma: 10,
      trend: :bullish, flip: false, # not a flip
      ohlc:
    )

    assert_no_changes 'StrategyBacktestTrade.count' do
      StrategyBacktestService.call(strategy_backtest: sb, smoothed_trends: [smoothed_trend])
    end
  end

  test 'skips candle when SMMA values are missing for the strategy intervals' do
    strategy = Strategy.create!(
      name: 'test_skip_missing_smma',
      fast_interval: 99, slow_interval: 199, # intervals that have no SMMA data
      entry_on: 'bullish', exit_on: 'neutral_or_bearish',
      slippage: 0.02, fee: 0.02
    )
    sb = build_strategy_backtest(strategy:)
    ohlc = ohlcs(:atom20230101)

    smoothed_trend = SmoothedTrend.create!(
      asset_pair_id: ohlc.asset_pair_id,
      iso8601_duration: ohlc.iso8601_duration,
      range_position: ohlc.range_position,
      fast_smma: 15, slow_smma: 10,
      trend: :bullish, flip: true,
      ohlc:
    )

    assert_no_changes 'StrategyBacktestTrade.count' do
      StrategyBacktestService.call(strategy_backtest: sb, smoothed_trends: [smoothed_trend])
    end
  end

  test 'updates last_range_position and current_value' do
    strategy = Strategy.create!(
      name: 'test_state_update',
      fast_interval: 10, slow_interval: 20,
      entry_on: 'bullish', exit_on: 'neutral_or_bearish',
      slippage: 0.02, fee: 0.02
    )
    sb = build_strategy_backtest(strategy:)
    sb.update!(usd_volume: 5, token_volume: 5)
    ohlc = ohlcs(:atom20230101)
    ohlc.update!(close: 100)

    smoothed_trend = SmoothedTrend.create!(
      asset_pair_id: ohlc.asset_pair_id,
      iso8601_duration: ohlc.iso8601_duration,
      range_position: ohlc.range_position,
      fast_smma: 15, slow_smma: 10,
      trend: :bullish, flip: false,
      ohlc:
    )

    assert_changes 'sb.reload.last_range_position', to: ohlc.range_position do
      StrategyBacktestService.call(strategy_backtest: sb, smoothed_trends: [smoothed_trend])
    end

    assert_equal 505, sb.reload.current_value
  end
end
