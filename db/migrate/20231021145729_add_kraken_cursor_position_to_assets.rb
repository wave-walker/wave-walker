# frozen_string_literal: true

class AddKrakenCursorPositionToAssets < ActiveRecord::Migration[7.1]
  def change
    remove_column :assets, :last_synced_trade_at, :timestamp # rubocop:todo Rails/BulkChangeTable
    add_column :assets, :kraken_cursor_position, :bigint, default: 0, null: false
  end
end
