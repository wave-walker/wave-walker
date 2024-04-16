# frozen_string_literal: true

class OhlcJob < ApplicationJob
  include GoodJob::ActiveJobExtensions::Concurrency
  include JobIteration::Iteration

  good_job_control_concurrency_with(
    total_limit: 1,
    key: -> { "#{self.class.name}-#{arguments[0].fetch(:asset_pair).id}-#{arguments[0].fetch(:duration)}" }
  )

  queue_as :default

  def build_enumerator(attr, cursor:)
    OhlcRangeEnumerator.call(**attr, cursor:)
  end

  def each_iteration(range, attr)
    ohlc = OhlcService.call(range:, asset_pair: attr.fetch(:asset_pair))
    SmoothedTrendService.call(ohlc)
  end
end
