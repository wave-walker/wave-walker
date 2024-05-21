# frozen_string_literal: true

class AddCurrentValueToBacktest < ActiveRecord::Migration[7.1]
  def change
    add_column :backtests, :current_value, :numeric
  end
end
