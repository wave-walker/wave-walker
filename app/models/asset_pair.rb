# frozen_string_literal: true

class AssetPair < ApplicationRecord
  has_many :trades, dependent: :restrict_with_error
  has_many :backtests, dependent: :destroy

  after_create :create_backtests

  scope :importing, -> { where(importing: true) }
  scope :pending, -> { where(importing: false) }

  def import = update!(importing: true)
  def disable_import = update!(importing: false)

  def reset_backtests
    ActiveRecord::Base.transaction do
      backtests.destroy_all
      create_backtests
    end
  end

  private

  def create_backtests
    Ohlc.durations.each do |duration|
      Backtest.create!(
        asset_pair: self,
        duration:
      )
    end
  end
end
