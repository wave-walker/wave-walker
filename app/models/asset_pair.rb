class AssetPair < ApplicationRecord
  has_many :trades, dependent: :restrict_with_error

  after_create :add_trade_partition_for_asset

  def import_later
    raise "Already importing!" if importing?

    TradeSyncJob.perform_later(self)
    update!(importing: true)
  end

  private

  def add_trade_partition_for_asset
    Trade.create_partition_for_asset(id, name)
  end
end
