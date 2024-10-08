# frozen_string_literal: true

class OhlcService
  def self.call(**) = new(**).call

  def initialize(asset_pair:, range:)
    @asset_pair = asset_pair
    @range = range
  end

  def call
    return if trades.empty? && previous_close.blank?

    Ohlc.create!(open:, close:, high:, low:, volume:, duration:, asset_pair:, range_position:)
  end

  private

  attr_reader :asset_pair, :range

  def range_position = range.position
  def duration = range.duration
  def trades = @trades ||= asset_pair.trades.where(created_at: range).load
  def open = trades.first&.price || previous_close
  def close = trades.last&.price || previous_close
  def high = trades.map(&:price).max || previous_close
  def low = trades.map(&:price).min || previous_close
  def volume = trades.map(&:volume).sum
  def previous_close = Ohlc.where(asset_pair:).by_duration(duration).last&.close
end
