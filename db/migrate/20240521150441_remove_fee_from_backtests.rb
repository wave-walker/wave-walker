class RemoveFeeFromBacktests < ActiveRecord::Migration[7.1]
  def change
    remove_column :backtests, :fee, :numeric, null: false, default: 0
  end
end
