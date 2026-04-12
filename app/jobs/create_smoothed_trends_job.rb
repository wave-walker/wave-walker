# frozen_string_literal: true

class CreateSmoothedTrendsJob < ApplicationJob
  include JobIteration::Iteration

  queue_as :default

  limits_concurrency key: ->(**attr) { "#{attr.fetch(:asset_pair).id}-#{attr.fetch(:duration)}" },
                     on_conflict: :discard

  def build_enumerator(attr, cursor:)
    asset_pair = attr.fetch(:asset_pair)
    duration = attr.fetch(:duration)

    base_scope = Ohlc
      .where(asset_pair: asset_pair)
      .by_duration(duration)
      .without_smoothed_trend
      .with_complete_smmas(SmoothedMovingAverage::INTERVALS)

    enumerator_builder.active_record_on_batches(base_scope, cursor:)
  end

  def each_iteration(ohlcs, _attr)
    SmoothedTrendService.call(ohlcs)
  end
end
