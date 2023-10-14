class Trade < ApplicationRecord
  belongs_to :asset

  def self.create_partition_for_asset(asset_id, asset_name)
    sql = <<-SQL
      CREATE TABLE asset_#{asset_name.downcase}_trades PARTITION OF trades
        FOR VALUES IN (#{asset_id});
    SQL

    ActiveRecord::Base.connection.execute(sql)
  end
end
