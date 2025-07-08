# frozen_string_literal: true

class AddConstraints < ActiveRecord::Migration[8.0]
  def change
    add_check_constraint :backtest_trades, "iso8601_duration IN ('PT1H', 'PT4H', 'PT8H', 'P1D', 'P2D', 'P1W')"
    add_check_constraint :backtests, "iso8601_duration IN ('PT1H', 'PT4H', 'PT8H', 'P1D', 'P2D', 'P1W')"
    add_check_constraint :ohlcs, "iso8601_duration IN ('PT1H', 'PT4H', 'PT8H', 'P1D', 'P2D', 'P1W')"
    add_check_constraint :smoothed_moving_averages, "iso8601_duration IN ('PT1H', 'PT4H', 'PT8H', 'P1D', 'P2D', 'P1W')"
    add_check_constraint :smoothed_trends, "iso8601_duration IN ('PT1H', 'PT4H', 'PT8H', 'P1D', 'P2D', 'P1W')"

    add_check_constraint :trades, "order_type IN ('market', 'limit')"

    add_check_constraint :trades, "action IN ('buy', 'sell')"
    add_check_constraint :backtest_trades, "action IN ('buy', 'sell')"

    add_check_constraint :smoothed_trends, "trend IN ('bearish', 'neutral', 'bullish')"
  end
end
