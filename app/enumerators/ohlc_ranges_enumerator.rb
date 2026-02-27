# frozen_string_literal: true

class OhlcRangesEnumerator
  def self.call(**) = new(**).to_enum(:each).lazy

  def initialize(asset_pair:, duration:, cursor: nil)
    @asset_pair = asset_pair
    @duration = duration
    @cursor = cursor
  end

  def each
    loop do
      ranges = build_ohlc_ranges
      break if ranges.empty?

      self.cursor = ranges.last.next.position

      yield ranges, cursor
    end
  end

  private

  attr_reader :asset_pair, :duration
  attr_writer :cursor

  def start_ohlc_range = NextNewOhlcRangeValueService.call(asset_pair:, duration:)
  def cursor = @cursor ||= start_ohlc_range.position

  def build_ohlc_ranges
    (0..99).to_a.filter_map do |index|
      range = OhlcRangeValue.new(position: cursor + index, duration:)
      next if range.end_at > asset_pair.imported_until - 10.seconds

      range
    end
  end
end
