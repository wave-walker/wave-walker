# frozen_string_literal: true

require 'test_helper'

class StrategyBacktestTest < ActiveSupport::TestCase
  test '#usd_volume defaults to BACKTEST_FUND on create' do
    strategy = strategies(:default)
    asset_pair = asset_pairs(:atomusd)

    sb = StrategyBacktest.create!(strategy:, asset_pair:, duration: 1.hour)

    assert_equal Backtest::BACKTEST_FUND, sb.usd_volume
  end

  test '#current_value defaults to BACKTEST_FUND on create' do
    strategy = strategies(:default)
    asset_pair = asset_pairs(:atomusd)

    sb = StrategyBacktest.create!(strategy:, asset_pair:, duration: 1.hour)

    assert_equal Backtest::BACKTEST_FUND, sb.current_value
  end

  test '#percentage_change returns 0 when at starting value' do
    strategy = strategies(:default)
    asset_pair = asset_pairs(:atomusd)
    sb = StrategyBacktest.new(strategy:, asset_pair:, usd_volume: Backtest::BACKTEST_FUND,
                              current_value: Backtest::BACKTEST_FUND)

    assert_equal 0, sb.percentage_change
  end

  test '#percentage_change returns positive when above starting value' do
    strategy = strategies(:default)
    asset_pair = asset_pairs(:atomusd)
    sb = StrategyBacktest.new(strategy:, asset_pair:, usd_volume: 0,
                              current_value: 12_000)

    assert_in_delta 20.0, sb.percentage_change, 0.001
  end

  test '#new_smoothed_trends returns trends after last_range_position' do
    strategy = strategies(:default)
    asset_pair = asset_pairs(:atomusd)
    StrategyBacktest.create!(strategy:, asset_pair:, duration: 1.hour)

    SmoothedTrendService.call(ohlcs(:atom20230101))
    SmoothedTrendService.call(ohlcs(:atom20230102))

    # The daily smoothed trends share asset_pair_id but have P1D duration, not PT1H
    # so this backtest (PT1H) won't see them — use the existing fixture which is P1D
    sb_daily = strategy_backtests(:atom_daily)
    sb_daily.update!(last_range_position: ohlcs(:atom20230101).range_position)

    assert_equal 1, sb_daily.new_smoothed_trends.count
    assert_equal ohlcs(:atom20230102).range_position, sb_daily.new_smoothed_trends.first.range_position
  end
end
