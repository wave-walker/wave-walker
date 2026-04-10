# frozen_string_literal: true

class CreateStrategies < ActiveRecord::Migration[8.1]
  def change
    create_table :strategies do |t|
      t.string  :name,           null: false
      t.integer :fast_interval,  null: false
      t.integer :slow_interval,  null: false
      t.string  :entry_on,       null: false
      t.string  :exit_on,        null: false
      t.decimal :slippage,       null: false
      t.decimal :fee,            null: false

      t.timestamps
    end

    add_index :strategies, :name, unique: true

    add_check_constraint :strategies, "entry_on IN ('bullish', 'bullish_or_neutral')"
    add_check_constraint :strategies, "exit_on IN ('neutral_or_bearish', 'bearish_only')"
  end
end
