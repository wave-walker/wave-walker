class CreateOhlcs < ActiveRecord::Migration[7.1]
  def change
    create_enum :timeframe, %w[PT1H PT4H PT8H P1D P2D P1W]

    create_table :ohlcs do |t|
      t.references :asset_pair, null: false, foreign_key: true
      t.datetime :start_at, null: false
      t.enum :timeframe, enum_type: "timeframe", null: false
      t.float :open, null: false
      t.float :high, null: false
      t.float :low, null: false
      t.float :close, null: false
      t.float :volume, null: false

      t.timestamps
    end
  end
end
