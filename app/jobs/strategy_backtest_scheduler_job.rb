# frozen_string_literal: true

class StrategyBacktestSchedulerJob < ApplicationJob
  include JobIteration::Iteration

  queue_as :low

  def build_enumerator(cursor:)
    enumerator_builder.active_record_on_records(
      StrategyBacktest.joins(:asset_pair).merge(AssetPair.importing),
      cursor:
    )
  end

  def each_iteration(strategy_backtest)
    StrategyBacktestJob.perform_later(strategy_backtest)
  end
end
