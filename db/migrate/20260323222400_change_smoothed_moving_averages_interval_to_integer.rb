# frozen_string_literal: true

class ChangeSmoothedMovingAveragesIntervalToInteger < ActiveRecord::Migration[8.1]
  def up
    change_column :smoothed_moving_averages, :interval, :integer, null: false
  end

  def down
    change_column :smoothed_moving_averages, :interval, :string, null: false
  end
end
