class Asset < ApplicationRecord
  has_many :trades, dependent: :restrict_with_error

  after_create :add_trade_partition_for_asset

  def usd_trading_pair = "#{name}USD"

  private

  def add_trade_partition_for_asset
    Trade.create_partition_for_asset(id, name)
  end
end
