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

ActiveRecord::Schema[8.0].define(version: 2025_03_08_161752) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  # Custom types defined in this database.
  # Note that some types may not work with other database engines. Be careful if changing database.
  create_enum "iso8601_duration", ["PT1H", "PT4H", "PT8H", "P1D", "P2D", "P1W"]
  create_enum "order_type", ["market", "limit"]
  create_enum "trade_action", ["buy", "sell"]
  create_enum "trend", ["bearish", "neutral", "bullish"]

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "asset_pairs", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "importing", default: false, null: false
    t.string "name_on_exchange", null: false
    t.datetime "imported_until"
    t.string "quote", null: false
    t.string "base", null: false
    t.integer "cost_decimals", null: false
    t.index ["name"], name: "index_asset_pairs_on_name", unique: true
    t.index ["name_on_exchange"], name: "index_asset_pairs_on_name_on_exchange", unique: true
  end

  create_table "backtest_trades", primary_key: ["asset_pair_id", "iso8601_duration", "range_position"], force: :cascade do |t|
    t.bigint "asset_pair_id", null: false
    t.enum "iso8601_duration", null: false, enum_type: "iso8601_duration"
    t.bigint "range_position", null: false
    t.enum "action", null: false, enum_type: "trade_action"
    t.decimal "volume", null: false
    t.decimal "fee", null: false
    t.decimal "price", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["asset_pair_id"], name: "index_backtest_trades_on_asset_pair_id"
  end

  create_table "backtests", primary_key: ["asset_pair_id", "iso8601_duration"], force: :cascade do |t|
    t.bigint "asset_pair_id", null: false
    t.enum "iso8601_duration", null: false, enum_type: "iso8601_duration"
    t.bigint "last_range_position", default: 0, null: false
    t.decimal "token_volume", default: "0.0", null: false
    t.decimal "usd_volume", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "current_value"
    t.index ["asset_pair_id"], name: "index_backtests_on_asset_pair_id"
  end

  create_table "ohlcs", primary_key: ["asset_pair_id", "iso8601_duration", "range_position"], force: :cascade do |t|
    t.bigint "asset_pair_id", null: false
    t.enum "iso8601_duration", null: false, enum_type: "iso8601_duration"
    t.bigint "range_position", null: false
    t.decimal "open", null: false
    t.decimal "high", null: false
    t.decimal "low", null: false
    t.decimal "close", null: false
    t.decimal "volume", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "smoothed_moving_averages", primary_key: ["asset_pair_id", "iso8601_duration", "range_position", "interval"], force: :cascade do |t|
    t.bigint "asset_pair_id", null: false
    t.enum "iso8601_duration", null: false, enum_type: "iso8601_duration"
    t.bigint "range_position", null: false
    t.integer "interval", null: false
    t.decimal "value", null: false
    t.datetime "created_at", precision: nil, null: false
  end

  create_table "smoothed_trends", primary_key: ["asset_pair_id", "iso8601_duration", "range_position"], force: :cascade do |t|
    t.bigint "asset_pair_id", null: false
    t.enum "iso8601_duration", null: false, enum_type: "iso8601_duration"
    t.bigint "range_position", null: false
    t.decimal "fast_smma", null: false
    t.decimal "slow_smma", null: false
    t.enum "trend", null: false, enum_type: "trend"
    t.datetime "created_at", precision: nil, null: false
    t.boolean "flip", null: false
  end

  create_table "trades", primary_key: ["asset_pair_id", "id"], force: :cascade do |t|
    t.bigint "id", null: false
    t.bigint "asset_pair_id", null: false
    t.decimal "price", null: false
    t.decimal "volume", null: false
    t.datetime "created_at", precision: nil, null: false
    t.enum "action", null: false, enum_type: "trade_action"
    t.enum "order_type", null: false, enum_type: "order_type"
    t.string "misc", null: false
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
  add_foreign_key "trades", "asset_pairs"
end
