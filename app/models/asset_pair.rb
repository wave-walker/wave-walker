# frozen_string_literal: true

class AssetPair < ApplicationRecord
  has_many :trades, dependent: :restrict_with_error

  after_create { PartitionService.call(self) }

  scope :importing, -> { where(importing: true) }
  scope :pending, -> { where(importing: false) }

  def import = update!(importing: true)
end
