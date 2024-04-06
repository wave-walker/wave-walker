# frozen_string_literal: true

class RenameOhlcsTimeframeToDuration < ActiveRecord::Migration[7.1]
  def change
    rename_column :ohlcs, :timeframe, :duration
  end
end
