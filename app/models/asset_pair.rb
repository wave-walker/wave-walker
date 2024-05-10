# frozen_string_literal: true

class AssetPair < ApplicationRecord
  has_many :trades, dependent: :restrict_with_error
  has_many :backtests, dependent: :destroy

  after_create :create_backtests

  scope :importing, -> { where(importing: true) }
  scope :pending, -> { where(importing: false) }

  def import = update!(importing: true)

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
