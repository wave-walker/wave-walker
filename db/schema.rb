# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_04_10_000003) do
  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "asset_pairs", force: :cascade do |t|
    t.string "base", null: false
    t.integer "cost_decimals", null: false
    t.datetime "created_at", null: false
    t.datetime "imported_until"
    t.boolean "importing", default: false, null: false
    t.datetime "missing_on_exchange_at"
    t.string "name", null: false
    t.string "name_on_exchange", null: false
    t.string "quote", null: false
    t.datetime "updated_at", null: false
    t.index ["missing_on_exchange_at"], name: "index_asset_pairs_on_missing_on_exchange_at"
    t.index ["name"], name: "index_asset_pairs_on_name", unique: true
    t.index ["name_on_exchange"], name: "index_asset_pairs_on_name_on_exchange", unique: true
  end

  create_table "backtest_trades", primary_key: ["asset_pair_id", "iso8601_duration", "range_position"], force: :cascade do |t|
    t.string "action", null: false
    t.bigint "asset_pair_id", null: false
    t.datetime "created_at", null: false
    t.decimal "fee", null: false
    t.string "iso8601_duration", null: false
    t.decimal "price", null: false
    t.bigint "range_position", null: false
    t.datetime "updated_at", null: false
    t.decimal "volume", null: false
    t.index ["asset_pair_id"], name: "index_backtest_trades_on_asset_pair_id"
    t.check_constraint "action IN ('buy', 'sell')"
    t.check_constraint "iso8601_duration IN ('PT1H', 'PT4H', 'PT8H', 'P1D', 'P2D', 'P1W')"
  end

  create_table "backtests", primary_key: ["asset_pair_id", "iso8601_duration"], force: :cascade do |t|
    t.bigint "asset_pair_id", null: false
    t.datetime "created_at", null: false
    t.decimal "current_value"
    t.string "iso8601_duration", null: false
    t.bigint "last_range_position", default: 0, null: false
    t.decimal "token_volume", default: "0.0", null: false
    t.datetime "updated_at", null: false
    t.decimal "usd_volume", null: false
    t.index ["asset_pair_id"], name: "index_backtests_on_asset_pair_id"
    t.check_constraint "iso8601_duration IN ('PT1H', 'PT4H', 'PT8H', 'P1D', 'P2D', 'P1W')"
  end

  create_table "ohlcs", primary_key: ["asset_pair_id", "iso8601_duration", "range_position"], force: :cascade do |t|
    t.bigint "asset_pair_id", null: false
    t.decimal "close", null: false
    t.datetime "created_at", null: false
    t.decimal "high", null: false
    t.string "iso8601_duration", null: false
    t.decimal "low", null: false
    t.decimal "open", null: false
    t.bigint "range_position", null: false
    t.datetime "updated_at", null: false
    t.decimal "volume", null: false
    t.check_constraint "iso8601_duration IN ('PT1H', 'PT4H', 'PT8H', 'P1D', 'P2D', 'P1W')"
  end

  create_table "smoothed_moving_averages", primary_key: ["asset_pair_id", "iso8601_duration", "range_position", "interval"], force: :cascade do |t|
    t.bigint "asset_pair_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.string "interval", null: false
    t.string "iso8601_duration", null: false
    t.bigint "range_position", null: false
    t.decimal "value", null: false
    t.check_constraint "iso8601_duration IN ('PT1H', 'PT4H', 'PT8H', 'P1D', 'P2D', 'P1W')"
  end

  create_table "smoothed_trends", primary_key: ["asset_pair_id", "iso8601_duration", "range_position"], force: :cascade do |t|
    t.bigint "asset_pair_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.decimal "fast_smma", null: false
    t.boolean "flip", null: false
    t.string "iso8601_duration", null: false
    t.bigint "range_position", null: false
    t.decimal "slow_smma", null: false
    t.string "trend", null: false
    t.check_constraint "iso8601_duration IN ('PT1H', 'PT4H', 'PT8H', 'P1D', 'P2D', 'P1W')"
    t.check_constraint "trend IN ('bearish', 'neutral', 'bullish')"
  end

  create_table "strategies", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "entry_on", null: false
    t.string "exit_on", null: false
    t.integer "fast_interval", null: false
    t.decimal "fee", null: false
    t.string "name", null: false
    t.decimal "slippage", null: false
    t.integer "slow_interval", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_strategies_on_name", unique: true
    t.check_constraint "entry_on IN ('bullish', 'bullish_or_neutral')"
    t.check_constraint "exit_on IN ('neutral_or_bearish', 'bearish_only')"
  end

  create_table "strategy_backtest_trades", primary_key: ["strategy_id", "asset_pair_id", "iso8601_duration", "range_position"], force: :cascade do |t|
    t.string "action", null: false
    t.integer "asset_pair_id", null: false
    t.datetime "created_at", null: false
    t.decimal "fee", null: false
    t.string "iso8601_duration", null: false
    t.decimal "price", null: false
    t.bigint "range_position", null: false
    t.integer "strategy_id", null: false
    t.datetime "updated_at", null: false
    t.decimal "volume", null: false
    t.index ["asset_pair_id"], name: "index_strategy_backtest_trades_on_asset_pair_id"
    t.index ["strategy_id"], name: "index_strategy_backtest_trades_on_strategy_id"
    t.check_constraint "action IN ('buy', 'sell')"
    t.check_constraint "iso8601_duration IN ('PT1H', 'PT4H', 'PT8H', 'P1D', 'P2D', 'P1W')"
  end

  create_table "strategy_backtests", primary_key: ["strategy_id", "asset_pair_id", "iso8601_duration"], force: :cascade do |t|
    t.integer "asset_pair_id", null: false
    t.datetime "created_at", null: false
    t.decimal "current_value"
    t.string "iso8601_duration", null: false
    t.bigint "last_range_position", default: 0, null: false
    t.integer "strategy_id", null: false
    t.decimal "token_volume", default: "0.0", null: false
    t.datetime "updated_at", null: false
    t.decimal "usd_volume", null: false
    t.index ["asset_pair_id"], name: "index_strategy_backtests_on_asset_pair_id"
    t.index ["strategy_id"], name: "index_strategy_backtests_on_strategy_id"
    t.check_constraint "iso8601_duration IN ('PT1H', 'PT4H', 'PT8H', 'P1D', 'P2D', 'P1W')"
  end

  create_table "trades", primary_key: ["asset_pair_id", "id"], force: :cascade do |t|
    t.string "action", null: false
    t.bigint "asset_pair_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.bigint "id", null: false
    t.string "misc", null: false
    t.string "order_type", null: false
    t.decimal "price", null: false
    t.decimal "volume", null: false
    t.check_constraint "action IN ('buy', 'sell')"
    t.check_constraint "order_type IN ('market', 'limit')"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "backtest_trades", "asset_pairs"
  add_foreign_key "backtest_trades", "ohlcs", column: ["asset_pair_id", "iso8601_duration", "range_position"], primary_key: ["asset_pair_id", "iso8601_duration", "range_position"]
  add_foreign_key "backtests", "asset_pairs"
  add_foreign_key "ohlcs", "asset_pairs"
  add_foreign_key "smoothed_moving_averages", "asset_pairs"
  add_foreign_key "smoothed_moving_averages", "ohlcs", column: ["asset_pair_id", "iso8601_duration", "range_position"], primary_key: ["asset_pair_id", "iso8601_duration", "range_position"]
  add_foreign_key "smoothed_trends", "asset_pairs"
  add_foreign_key "smoothed_trends", "ohlcs", column: ["asset_pair_id", "iso8601_duration", "range_position"], primary_key: ["asset_pair_id", "iso8601_duration", "range_position"]
  add_foreign_key "strategy_backtest_trades", "asset_pairs"
  add_foreign_key "strategy_backtest_trades", "ohlcs", column: ["asset_pair_id", "iso8601_duration", "range_position"], primary_key: ["asset_pair_id", "iso8601_duration", "range_position"]
  add_foreign_key "strategy_backtest_trades", "strategies"
  add_foreign_key "strategy_backtests", "asset_pairs"
  add_foreign_key "strategy_backtests", "strategies"
  add_foreign_key "trades", "asset_pairs"
end
