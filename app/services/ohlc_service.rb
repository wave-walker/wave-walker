# frozen_string_literal: true

class OhlcService
  def self.call(asset_pair:, ranges:)
    previous_close = Ohlc.where(asset_pair:)
                         .by_duration(ranges.first.duration)
                         .last&.close

    ohlcs = ranges.filter_map do |range|
      new(asset_pair:, range:, previous_close:)
        .call
        .tap { previous_close = it&.fetch(:close) }
    end

    Ohlc.insert_all!(ohlcs) if ohlcs.present? # rubocop:disable Rails/SkipsModelValidations
  end

  def initialize(asset_pair:, range:, previous_close:)
    @asset_pair = asset_pair
    @range = range
    @previous_close = previous_close
  end

  def call
    return if trades.empty? && previous_close.blank?

    { open:, close:, high:, low:, volume:, iso8601_duration: duration.iso8601, asset_pair_id: asset_pair.id,
      range_position: }
  end

  private

  attr_reader :asset_pair, :range, :previous_close

  def range_position = range.position
  def duration = range.duration
  def trades = @trades ||= asset_pair.trades.where(created_at: range).load
  def open = trades.first&.price || previous_close
  def close = trades.last&.price || previous_close
  def high = trades.map(&:price).max || previous_close
  def low = trades.map(&:price).min || previous_close
  def volume = trades.map(&:volume).sum
end
