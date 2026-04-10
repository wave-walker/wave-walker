# frozen_string_literal: true

class CreateStrategyBacktestTrades < ActiveRecord::Migration[8.1]
  def change
    create_table :strategy_backtest_trades,
                 primary_key: %i[strategy_id asset_pair_id iso8601_duration range_position] do |t|
      t.references :strategy,    null: false, foreign_key: true
      t.references :asset_pair,  null: false, foreign_key: true
      t.string     :iso8601_duration, null: false
      t.bigint     :range_position, null: false
      t.string     :action,      null: false
      t.decimal    :price,       null: false
      t.decimal    :volume,      null: false
      t.decimal    :fee,         null: false

      t.timestamps
    end

    add_check_constraint :strategy_backtest_trades,
                         "iso8601_duration IN ('PT1H', 'PT4H', 'PT8H', 'P1D', 'P2D', 'P1W')"
    add_check_constraint :strategy_backtest_trades,
                         "action IN ('buy', 'sell')"

    add_foreign_key :strategy_backtest_trades, :ohlcs,
                    column: %i[asset_pair_id iso8601_duration range_position],
                    primary_key: %i[asset_pair_id iso8601_duration range_position]
  end
end
