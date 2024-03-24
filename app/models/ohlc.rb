# frozen_string_literal: true

class Ohlc < ApplicationRecord
  enum timeframe: {
    PT1H: 'PT1H',
    PT4H: 'PT4H',
    PT8H: 'PT8H',
    P1D: 'P1D',
    P2D: 'P2D',
    P1W: 'P1W'
  }, _prefix: true

  belongs_to :asset_pair

  has_many :smoothed_moving_avrages, dependent: :destroy
  has_one :smoothed_trend, dependent: :destroy

  after_commit do
    OhlcAnalyzeJob.perform_later(self)
  end

  def self.generate_new_later(asset_pair, last_imported_at)
    timeframes.each_key do |timeframe|
      NewOhlcForTimeframeJob.perform_later(asset_pair, timeframe, last_imported_at)
    end
  end

  def self.last_end_at(asset_pair, timeframe)
    where(asset_pair:, timeframe:).last&.range&.last ||
      Range.new(timeframe, asset_pair.trades.first.created_at).begin
  end

  def self.create_from_trades(asset_pair, timeframe, range) # rubocop:todo Metrics/MethodLength, Metrics/AbcSize
    trades = asset_pair.trades.where(created_at: range).to_a
    prices = trades.map(&:price)

    if trades.any?
      create!(
        asset_pair:,
        high: prices.max,
        low: prices.min,
        open: prices.first,
        close: prices.last,
        volume: trades.sum(&:volume),
        timeframe:,
        start_at: range.begin
      )
    else
      close = Ohlc.where(asset_pair:, timeframe:).last.close

      create!(
        asset_pair:,
        high: close,
        low: close,
        open: close,
        close:,
        volume: 0,
        timeframe:,
        start_at: range.begin
      )
    end
  end

  def hl2 = (high + low) / 2

  def previous_ohlcs
    self.class.where(id: ...id, asset_pair:, timeframe:).order(id: :desc)
  end

  def range
    @range ||= Range.new(timeframe, start_at)
  end
end
