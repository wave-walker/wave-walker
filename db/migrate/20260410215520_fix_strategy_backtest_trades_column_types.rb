# frozen_string_literal: true

class FixStrategyBacktestTradesColumnTypes < ActiveRecord::Migration[8.1]
  def change
    change_column :strategy_backtest_trades, :strategy_id,   :bigint
    change_column :strategy_backtest_trades, :asset_pair_id, :bigint
    change_column :strategy_backtests,       :strategy_id,   :bigint
    change_column :strategy_backtests,       :asset_pair_id, :bigint
  end
end
