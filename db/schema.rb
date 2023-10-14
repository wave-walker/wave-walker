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

ActiveRecord::Schema[7.1].define(version: 2023_10_14_055916) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "assets", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_assets_on_name", unique: true
  end

  create_table "trades", force: :cascade do |t|
    t.decimal "price", precision: 20, scale: 10, null: false
    t.decimal "volume", precision: 20, scale: 10, null: false
    t.datetime "created_at", precision: nil, null: false
    t.bigint "asset_id", null: false
    t.index ["asset_id"], name: "index_trades_on_asset_id"
  end

  add_foreign_key "trades", "assets"
end
