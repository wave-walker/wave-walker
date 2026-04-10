# frozen_string_literal: true

class AddDefaultUsdVolumeToStrategyBacktests < ActiveRecord::Migration[8.1]
  def change
    change_column_default :strategy_backtests, :usd_volume, from: nil, to: 10_000
  end
end
