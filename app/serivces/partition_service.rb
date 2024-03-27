# frozen_string_literal: true

class PartitionService
  def self.call(*) = new(*).call

  def initialize(asset_pair)
    @asset_pair = asset_pair
  end

  def call
    ActiveRecord::Base.connection.execute(<<-SQL.squish)
      CREATE TABLE IF NOT EXISTS #{trades_table}
        PARTITION OF trades
        FOR VALUES IN (#{asset_pair.id});
    SQL
  end

  private

  attr_reader :asset_pair

  def trades_table = "asset_#{asset_pair.name.downcase.gsub('.', '_')}_trades"
end
