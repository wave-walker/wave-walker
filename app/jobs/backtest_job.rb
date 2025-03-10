# frozen_string_literal: true

class BacktestJob < ApplicationJob
  include JobIteration::Iteration

  limits_concurrency key: ->(backtest) { backtest }

  queue_as :default

  def build_enumerator(backtest, cursor:)
    enumerator_builder.active_record_on_batches(
      backtest.new_smoothed_trends,
      cursor:
    )
  end

  def each_iteration(smoothed_trends, backtest)
    BacktestService.call(backtest:, smoothed_trends:)
  end
end
