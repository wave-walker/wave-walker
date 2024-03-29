# frozen_string_literal: true

class OhlcRangeEnumerator
  def self.call(**) = new(**).to_enum(:each).lazy

  def initialize(asset_pair:, timeframe:, cursor: nil)
    @asset_pair = asset_pair
    @timeframe = timeframe
    @cursor = cursor
  end

  def each
    loop do
      break if after_last_import?

      yield cursor, set_next_cursor
    end
  end

  private

  attr_reader :asset_pair, :timeframe
  attr_writer :cursor

  def after_last_import? = cursor.end > asset_pair.imported_until - 10.seconds

  def cursor
    @cursor ||= Ohlc::Range.next_new_range(asset_pair:, timeframe:)
  end

  def set_next_cursor = self.cursor = cursor.next
end
