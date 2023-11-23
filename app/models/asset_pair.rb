class AssetPair < ApplicationRecord
  has_many :trades, dependent: :restrict_with_error

  after_create :add_trade_partition_for_asset

  enum import_status: {
    pending: 'pending',
    waiting: 'waiting',
    importing: 'importing',
    imported: 'imported'
  }

  def start_import
    raise "Already importing!" if importing?

    importing!
    TradeSyncJob.perform_later(self)
  rescue ActiveRecord::RecordNotUnique
    waiting!
  end

  def finish_import
    raise "Not importing!" unless importing?

    imported!
    self.class.where(import_status: :waiting).first&.start_import
    OhlcGenerateJob.perform_later(self, Time.current)
  end

  private

  def add_trade_partition_for_asset
    Trade.create_partition_for_asset(id, name)
  end
end
