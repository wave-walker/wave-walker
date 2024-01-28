# frozen_string_literal: true

class OhlcForm
  def initialize(asset_pair:, range:)
    @asset_pair = asset_pair
    @range = range
  end

  def save
    return if trades.none?

    Ohlc.create!(open:, close:, high:, low:, volume:, timeframe:, asset_pair:, start_at:)
  end

  private

  attr_reader :asset_pair, :range

  def start_at = range.first
  def timeframe = range.timeframe
  def trades = @trades ||= asset_pair.trades.where(created_at: range).load
  def open = trades.first.price
  def close = trades.last.price
  def high = trades.map(&:price).max
  def low = trades.map(&:price).min
  def volume = trades.map(&:volume).sum
end
