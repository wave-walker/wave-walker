# frozen_string_literal: true

class AssetPair < ApplicationRecord
  has_many :trades, dependent: :restrict_with_error

  after_create :add_trade_partition_for_asset

  scope :importing, -> { where(importing: true) }

  def import = update!(importing: true)

  private

  def add_trade_partition_for_asset
    Trade.create_partition_for_asset(id, name)
  end
end
