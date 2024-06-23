# frozen_string_literal: true

class UseVolumeAndPriceInBacktestTrades < ActiveRecord::Migration[7.1]
  def change
    remove_foreign_key :backtest_trades, :ohlcs, column: %i[asset_pair_id iso8601_duration range_position],
                                                 primary_key: %i[asset_pair_id iso8601_duration range_position]

    drop_table :backtest_trades, primary_key: %i[asset_pair_id iso8601_duration range_position] do |t|
      t.references :asset_pair, null: false, foreign_key: true
      t.enum :iso8601_duration, enum_type: :iso8601_duration, null: false
      t.bigint :range_position, null: false
      t.enum :trade_type, enum_type: :trade_action, null: false
      t.numeric :quantity, null: false
      t.numeric :fee, null: false
      t.numeric :price, null: false

      t.timestamps
    end

    drop_enum :trade_type, %w[buy sell]

    create_table :backtest_trades, primary_key: %i[asset_pair_id iso8601_duration range_position] do |t|
      t.references :asset_pair, null: false, foreign_key: true
      t.enum :iso8601_duration, enum_type: :iso8601_duration, null: false
      t.bigint :range_position, null: false
      t.enum :action, enum_type: :trade_action, null: false
      t.numeric :volume, null: false
      t.numeric :fee, null: false
      t.numeric :price, null: false

      t.timestamps
    end

    add_foreign_key :backtest_trades, :ohlcs, column: %i[asset_pair_id iso8601_duration range_position],
                                              primary_key: %i[asset_pair_id iso8601_duration range_position]

    rename_column :backtests, :usd_quantity, :usd_volume
    rename_column :backtests, :token_quantity, :token_volume
  end
end
