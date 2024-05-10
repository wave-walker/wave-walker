# frozen_string_literal: true

class CreateBacktests < ActiveRecord::Migration[7.1]
  def change
    create_table :backtests, primary_key: %i[asset_pair_id iso8601_duration] do |t|
      t.references :asset_pair, null: false, foreign_key: true
      t.enum :iso8601_duration, enum_type: :iso8601_duration, null: false
      t.bigint :last_range_position, null: false, default: 0
      t.numeric :token_quantity, null: false, default: 0
      t.numeric :usd_quantity, null: false
      t.numeric :fee, null: false, default: 0

      t.timestamps
    end
  end
end
