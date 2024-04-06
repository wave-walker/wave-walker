# frozen_string_literal: true

class PartitionService
  def self.call(*) = new(*).call

  def initialize(asset_pair)
    @asset_pair_id = asset_pair.id
  end

  def call
    ActiveRecord::Base.connection.execute(trades_partition_sql)
    ActiveRecord::Base.connection.execute(ohlcs_partition_sql)
    ActiveRecord::Base.connection.execute(smoothed_moving_averages_partition_sql)
    ActiveRecord::Base.connection.execute(smoothed_trends_partition_sql)
  end

  private

  attr_reader :asset_pair_id

  def trades_partition_sql
    <<-SQL.squish
      CREATE TABLE IF NOT EXISTS asset_pair_#{asset_pair_id}_trades
        PARTITION OF trades
        FOR VALUES IN (#{asset_pair_id});
    SQL
  end

  def ohlcs_partition_sql
    <<-SQL.squish
      CREATE TABLE IF NOT EXISTS asset_pair_#{asset_pair_id}_ohlcs
        PARTITION OF ohlcs
        FOR VALUES IN (#{asset_pair_id});
    SQL
  end

  def smoothed_moving_averages_partition_sql
    <<-SQL.squish
      CREATE TABLE IF NOT EXISTS asset_pair_#{asset_pair_id}_smoothed_moving_averages
        PARTITION OF smoothed_moving_averages
        FOR VALUES IN (#{asset_pair_id});
    SQL
  end

  def smoothed_trends_partition_sql
    <<-SQL.squish
      CREATE TABLE IF NOT EXISTS asset_pair_#{asset_pair_id}_smoothed_trends
        PARTITION OF smoothed_trends
        FOR VALUES IN (#{asset_pair_id});
    SQL
  end
end
