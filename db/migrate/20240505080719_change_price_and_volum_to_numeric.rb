# frozen_string_literal: true

class ChangePriceAndVolumToNumeric < ActiveRecord::Migration[7.1]
  def up
    change_table :ohlcs, bulk: true do |t|
      t.change :open, :numeric
      t.change :close, :numeric
      t.change :high, :numeric
      t.change :low, :numeric
      t.change :volume, :numeric
    end

    change_column :smoothed_moving_averages, :value, :numeric

    change_table :smoothed_trends, bulk: true do |t|
      t.change :fast_smma, :numeric
      t.change :slow_smma, :numeric
    end

    change_table :trades, bulk: true do |t|
      t.change :price, :numeric
      t.change :volume, :numeric
    end
  end

  def down
    change_table :ohlcs, bulk: true do |t|
      t.change :open, :float
      t.change :close, :float
      t.change :high, :float
      t.change :low, :float
      t.change :volume, :float
    end

    change_column :smoothed_moving_averages, :value, :float

    change_table :smoothed_trends, bulk: true do |t|
      t.change :fast_smma, :float
      t.change :slow_smma, :float
    end

    change_table :trades, bulk: true do |t|
      t.change :price, :float
      t.change :volume, :float
    end
  end
end
