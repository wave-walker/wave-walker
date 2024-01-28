# frozen_string_literal: true

class Trade < ApplicationRecord
  belongs_to :asset_pair, counter_cache: true

  def self.create_partition_for_asset(asset_id, asset_name)
    sql = <<-SQL.squish
      CREATE TABLE IF NOT EXISTS asset_#{asset_name.downcase.gsub('.', '_')}_trades
        PARTITION OF trades
        FOR VALUES IN (#{asset_id});
    SQL

    ActiveRecord::Base.connection.execute(sql)
  end
end
