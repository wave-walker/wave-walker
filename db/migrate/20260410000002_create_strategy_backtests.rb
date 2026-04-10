# frozen_string_literal: true

class CreateStrategyBacktests < ActiveRecord::Migration[8.1]
  def change
    create_table :strategy_backtests, primary_key: %i[strategy_id asset_pair_id iso8601_duration] do |t|
      t.references :strategy,    null: false, foreign_key: true
      t.references :asset_pair,  null: false, foreign_key: true
      t.string     :iso8601_duration, null: false
      t.bigint     :last_range_position, null: false, default: 0
      t.decimal    :usd_volume,   null: false, default: 10_000
      t.decimal    :token_volume, null: false, default: 0.0
      t.decimal    :current_value

      t.timestamps
    end

    add_check_constraint :strategy_backtests,
                         "iso8601_duration IN ('PT1H', 'PT4H', 'PT8H', 'P1D', 'P2D', 'P1W')"
  end
end
