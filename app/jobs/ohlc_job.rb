# frozen_string_literal: true

class OhlcJob < ApplicationJob
  include GoodJob::ActiveJobExtensions::Concurrency
  include JobIteration::Iteration

  good_job_control_concurrency_with(
    total_limit: 1,
    key: -> { "#{self.class.name}-#{arguments[0]}-#{arguments[1]}" }
  )

  queue_as :default

  def self.enqueue_for_all_timeframes(asset_pair, last_imported_at)
    Ohlc.timeframes.each_key do |timeframe|
      perform_later(asset_pair:, timeframe:, last_imported_at:)
    end
  end

  def build_enumerator(attr, cursor:)
    OhlcRangeEnumerator.call(**attr, cursor:)
  end

  def each_iteration(range, attr)
    ohlc = OhlcService.call(range:, asset_pair: attr.fetch(:asset_pair))
    SmoothedTrendService.call(ohlc)
  end
end
