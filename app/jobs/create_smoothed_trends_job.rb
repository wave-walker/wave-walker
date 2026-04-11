# frozen_string_literal: true

class CreateSmoothedTrendsJob < ApplicationJob
  include JobIteration::Iteration

  queue_as :default

  limits_concurrency key: ->(**attr) { "#{attr.fetch(:asset_pair).id}-#{attr.fetch(:duration)}" },
                     on_conflict: :discard

  def build_enumerator(attr, cursor:)
    enumerator_builder.active_record_on_batches(
      Ohlc.where(asset_pair: attr.fetch(:asset_pair))
          .by_duration(attr.fetch(:duration))
          .left_outer_joins(:smoothed_trend)
          .where(smoothed_trends: { asset_pair_id: nil }),
      cursor:
    )
  end

  def each_iteration(ohlcs, _attr)
    SmoothedTrendService.call(ohlcs)
  end
end
