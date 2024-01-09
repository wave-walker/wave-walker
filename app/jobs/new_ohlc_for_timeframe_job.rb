# frozen_string_literal: true

class NewOhlcForTimeframeJob < ApplicationJob
  queue_as :default

  def perform(asset_pair, timeframe, last_import_at)
    last_end_at = Ohlc.last_end_at(asset_pair, timeframe)

    range = Ohlc::Range.new(timeframe, last_end_at)

    until range.cover?(last_import_at)
      Ohlc.create_from_trades(asset_pair, timeframe, range)
      range = range.next
    end
  end
end
