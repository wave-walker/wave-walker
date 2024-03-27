# frozen_string_literal: true

class OhlcJob < ApplicationJob
  include JobIteration::Iteration

  queue_as :default

  def self.enqueue_for_all_timeframes(asset_pair, last_imported_at)
    Ohlc.timeframes.each_key do |timeframe|
      perform_later(asset_pair, timeframe, last_imported_at)
    end
  end

  def build_enumerator(attr, cursor:)
    OhlcRangeEnumerator.call(**attr, cursor:)
  end

  def each_iteration(range, attr)
    OhlcService.call(range:, asset_pair: attr.fetch(:asset_pair))
  end
end
