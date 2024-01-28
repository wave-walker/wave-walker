# frozen_string_literal: true

class AddLastSyncedTradeAtToAssets < ActiveRecord::Migration[7.1]
  def change
    add_column :assets, :last_synced_trade_at, :timestamp
  end
end
