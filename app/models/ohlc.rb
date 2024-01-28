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

  def self.generate_new_later(asset_pair, last_imported_at)
    timeframes.each_key do |timeframe|
      NewOhlcForTimeframeJob.perform_later(asset_pair, timeframe, last_imported_at)
    end
  end
end
