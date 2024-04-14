# frozen_string_literal: true

class OhlcRangeEnumerator
  def self.call(**) = new(**).to_enum(:each).lazy

  def initialize(asset_pair:, duration:, cursor: nil)
    @asset_pair = asset_pair
    @duration = duration
    @cursor = cursor
  end

  def each
    loop do
      break if after_last_import?

      yield ohlc_range_value, set_next_cursor
    end
  end

  private

  attr_reader :asset_pair, :duration
  attr_writer :cursor

  def set_next_cursor = @cursor = cursor + 1
  def next_ohlc_range_value = NextNewOhlcRangeValueService.call(asset_pair:, duration:)
  def ohlc_range_value = OhlcRangeValue.new(position: cursor, duration:)
  def cursor = @cursor ||= next_ohlc_range_value.position
  def after_last_import? = ohlc_range_value.end_at > asset_pair.imported_until - 10.seconds
end
