# frozen_string_literal: true

class StrategyBacktestJob < ApplicationJob
  include JobIteration::Iteration

  limits_concurrency key: ->(strategy_backtest) { strategy_backtest }, on_conflict: :discard

  queue_as :default

  def build_enumerator(strategy_backtest, cursor:)
    enumerator_builder.active_record_on_batches(
      strategy_backtest.new_smoothed_trends,
      cursor:
    )
  end

  def each_iteration(smoothed_trends, strategy_backtest)
    StrategyBacktestService.call(strategy_backtest:, smoothed_trends:)
  end
end
