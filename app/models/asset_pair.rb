class AssetPair < ApplicationRecord
  has_many :trades, dependent: :restrict_with_error

  after_create :add_trade_partition_for_asset

  enum import_state: {
    pending: 'pending',
    waiting: 'waiting',
    importing: 'importing',
    imported: 'imported'
  }

  def self.import_waiting_later
    where(import_state: :waiting).first&.import_later
  end

  def import_later
    raise "Already importing!" if importing?

    TradeSyncJob.perform_later(self)
    importing!
  rescue ActiveRecord::RecordNotUnique
    waiting!
  end

  private

  def add_trade_partition_for_asset
    Trade.create_partition_for_asset(id, name)
  end
end
