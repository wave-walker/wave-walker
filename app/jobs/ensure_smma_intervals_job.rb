# frozen_string_literal: true

class EnsureSmmaIntervalsJob < ApplicationJob
  include JobIteration::Iteration

  limits_concurrency key: ->(strategy) { strategy }, on_conflict: :discard

  queue_as :default

  def build_enumerator(_strategy, cursor:)
    enumerator_builder.active_record_on_batches(
      Ohlc.joins(:asset_pair).merge(AssetPair.importing),
      cursor:
    )
  end

  def each_iteration(ohlcs, strategy)
    ohlcs.each do |ohlc|
      [strategy.fast_interval, strategy.slow_interval].each do |interval|
        next if SmoothedMovingAverage.exists?(
          asset_pair_id: ohlc.asset_pair_id,
          iso8601_duration: ohlc.iso8601_duration,
          range_position: ohlc.range_position,
          interval: interval.to_s
        )

        SmoothedMovingAverageService.call(ohlc:, interval:)
      end
    end
  end
end
