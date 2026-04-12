# frozen_string_literal: true

class CreateSmoothedMovingAveragesJob < ApplicationJob
  include JobIteration::Iteration

  queue_as :default

  limits_concurrency key: ->(**attr) { "#{attr.fetch(:asset_pair).id}-#{attr.fetch(:duration)}" },
                     on_conflict: :discard

  on_complete do
    attr = arguments.first
    CreateSmoothedTrendsJob.perform_later(
      asset_pair: attr.fetch(:asset_pair),
      duration: attr.fetch(:duration)
    )
  end

  def build_enumerator(attr, cursor:)
    enumerator_builder.active_record_on_batches(
      Ohlc.where(asset_pair: attr.fetch(:asset_pair))
          .by_duration(attr.fetch(:duration))
          .left_outer_joins(:smoothed_moving_averages)
          .where(smoothed_moving_averages: { asset_pair_id: nil })
          .distinct,
      cursor:
    )
  end

  def each_iteration(ohlcs, _attr)
    CreateSmoothedMovingAveragesService.call(ohlcs)
  end
end
