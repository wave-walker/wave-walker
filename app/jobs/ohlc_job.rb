# frozen_string_literal: true

class OhlcJob < ApplicationJob
  include JobIteration::Iteration

  limits_concurrency key: ->(**attr) { "#{attr.fetch(:asset_pair).id}-#{attr.fetch(:duration)}" },
                     on_conflict: :discard

  queue_as :default

  def build_enumerator(attr, cursor:)
    enumerator_builder.wrap(self, OhlcRangesEnumerator.call(**attr, cursor:))
  end

  def each_iteration(ranges, attr)
    # JobIteration strips the array for a single record.
    ranges = [ranges].flatten

    OhlcService.call(ranges:, asset_pair: attr.fetch(:asset_pair)).each do |ohlc|
      SmoothedTrendService.call(ohlc)
    end
  end
end
