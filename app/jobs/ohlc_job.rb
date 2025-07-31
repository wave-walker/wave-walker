# frozen_string_literal: true

class OhlcJob < ApplicationJob
  include JobIteration::Iteration

  limits_concurrency key: ->(**attr) { "#{attr.fetch(:asset_pair).id}-#{attr.fetch(:duration)}" },
                     on_conflict: :discard

  queue_as :default

  def build_enumerator(attr, cursor:)
    enumerator_builder.wrap(self, OhlcRangeEnumerator.call(**attr, cursor:))
  end

  def each_iteration(range, attr)
    ohlc = OhlcService.call(range:, asset_pair: attr.fetch(:asset_pair))
    SmoothedTrendService.call(ohlc)
  end
end
