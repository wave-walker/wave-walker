# frozen_string_literal: true

class RemoveEnumForSqliteMigration < ActiveRecord::Migration[8.0]
  def up
    drop_table :backtest_trades
    drop_table :backtests
    drop_table :smoothed_moving_averages
    drop_table :smoothed_trends
    drop_table :ohlcs
    drop_table :trades

    create_table 'backtest_trades', primary_key: %w[asset_pair_id iso8601_duration range_position] do |t|
      t.bigint 'asset_pair_id', null: false
      t.string 'iso8601_duration', null: false
      t.bigint 'range_position', null: false
      t.string 'action', null: false
      t.decimal 'volume', null: false
      t.decimal 'fee', null: false
      t.decimal 'price', null: false
      t.datetime 'created_at', null: false
      t.datetime 'updated_at', null: false
      t.index ['asset_pair_id'], name: 'index_backtest_trades_on_asset_pair_id'
    end

    create_table 'backtests', primary_key: %w[asset_pair_id iso8601_duration] do |t|
      t.bigint 'asset_pair_id', null: false
      t.string 'iso8601_duration', null: false
      t.bigint 'last_range_position', default: 0, null: false
      t.decimal 'token_volume', default: '0.0', null: false
      t.decimal 'usd_volume', null: false
      t.datetime 'created_at', null: false
      t.datetime 'updated_at', null: false
      t.decimal 'current_value'
      t.index ['asset_pair_id'], name: 'index_backtests_on_asset_pair_id'
    end

    create_table 'ohlcs', primary_key: %w[asset_pair_id iso8601_duration range_position] do |t|
      t.bigint 'asset_pair_id', null: false
      t.string 'iso8601_duration', null: false
      t.bigint 'range_position', null: false
      t.decimal 'open', null: false
      t.decimal 'high', null: false
      t.decimal 'low', null: false
      t.decimal 'close', null: false
      t.decimal 'volume', null: false
      t.datetime 'created_at', null: false
      t.datetime 'updated_at', null: false
    end

    create_table 'smoothed_moving_averages', primary_key: %w[asset_pair_id iso8601_duration range_position interval] do |t|
      t.bigint 'asset_pair_id', null: false
      t.string 'iso8601_duration', null: false
      t.bigint 'range_position', null: false
      t.string 'interval', null: false
      t.decimal 'value', null: false
      t.datetime 'created_at', precision: nil, null: false
    end

    create_table 'smoothed_trends', primary_key: %w[asset_pair_id iso8601_duration range_position] do |t|
      t.bigint 'asset_pair_id', null: false
      t.string 'iso8601_duration', null: false
      t.bigint 'range_position', null: false
      t.decimal 'fast_smma', null: false
      t.decimal 'slow_smma', null: false
      t.string 'trend', null: false
      t.datetime 'created_at', precision: nil, null: false
      t.boolean 'flip', null: false # rubocop:disable Rails/ThreeStateBooleanColumn
    end

    create_table 'trades', primary_key: %w[asset_pair_id id] do |t|
      t.bigint 'id', null: false # rubocop:disable Rails/DangerousColumnNames
      t.bigint 'asset_pair_id', null: false
      t.decimal 'price', null: false
      t.decimal 'volume', null: false
      t.datetime 'created_at', precision: nil, null: false
      t.string 'action', null: false
      t.string 'order_type', null: false
      t.string 'misc', null: false
    end

    drop_enum 'iso8601_duration', %w[PT1H PT4H PT8H P1D P2D P1W]
    drop_enum 'order_type', %w[market limit]
    drop_enum 'trade_action', %w[buy sell]
    drop_enum 'trend', %w[bearish neutral bullish]

    add_check_constraint :backtest_trades, "iso8601_duration IN ('PT1H', 'PT4H', 'PT8H', 'P1D', 'P2D', 'P1W')"
    add_check_constraint :backtests, "iso8601_duration IN ('PT1H', 'PT4H', 'PT8H', 'P1D', 'P2D', 'P1W')"
    add_check_constraint :ohlcs, "iso8601_duration IN ('PT1H', 'PT4H', 'PT8H', 'P1D', 'P2D', 'P1W')"
    add_check_constraint :smoothed_moving_averages, "iso8601_duration IN ('PT1H', 'PT4H', 'PT8H', 'P1D', 'P2D', 'P1W')"
    add_check_constraint :smoothed_trends, "iso8601_duration IN ('PT1H', 'PT4H', 'PT8H', 'P1D', 'P2D', 'P1W')"

    add_check_constraint :trades, "order_type IN ('market', 'limit')"

    add_check_constraint :trades, "action IN ('buy', 'sell')"
    add_check_constraint :backtest_trades, "action IN ('buy', 'sell')"

    add_check_constraint :smoothed_trends, "trend IN ('bearish', 'neutral', 'bullish')"

    add_foreign_key 'backtest_trades', 'asset_pairs'
    add_foreign_key 'backtest_trades', 'ohlcs', column: %w[asset_pair_id iso8601_duration range_position], primary_key: %w[asset_pair_id iso8601_duration range_position]
    add_foreign_key 'backtests', 'asset_pairs'
    add_foreign_key 'ohlcs', 'asset_pairs'
    add_foreign_key 'smoothed_moving_averages', 'asset_pairs'
    add_foreign_key 'smoothed_moving_averages', 'ohlcs', column: %w[asset_pair_id iso8601_duration range_position], primary_key: %w[asset_pair_id iso8601_duration range_position]
    add_foreign_key 'smoothed_trends', 'asset_pairs'
    add_foreign_key 'smoothed_trends', 'ohlcs', column: %w[asset_pair_id iso8601_duration range_position], primary_key: %w[asset_pair_id iso8601_duration range_position]
    add_foreign_key 'trades', 'asset_pairs'
  end
end
