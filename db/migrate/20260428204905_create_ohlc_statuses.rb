# frozen_string_literal: true

class CreateOhlcStatuses < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL.squish
      CREATE VIEW ohlc_statuses AS
        SELECT
          asset_pair_id,
          iso8601_duration,
          MAX(range_position) AS latest_range_position
        FROM ohlcs
        GROUP BY asset_pair_id, iso8601_duration;
    SQL
  end

  def down
    execute <<~SQL.squish
      DROP VIEW ohlc_statuses;
    SQL
  end
end
