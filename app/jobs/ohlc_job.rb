# frozen_string_literal: true

class OhlcJob < ApplicationJob
  queue_as :default

  def self.enqueue_for_all_timeframes(asset_pair, last_imported_at)
    Ohlc.timeframes.each_key do |timeframe|
      perform_later(asset_pair, timeframe, last_imported_at)
    end
  end

  def perform(asset_pair, timeframe, last_import_at)
    last_end_at = Ohlc.last_end_at(asset_pair, timeframe)

    range = Ohlc::Range.new(timeframe, last_end_at)

    until range.cover?(last_import_at)
      Ohlc.create_from_trades(asset_pair, timeframe, range)
      range = range.next
      sleep 0.1 # throttel
    end
  end
end
