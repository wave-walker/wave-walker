# frozen_string_literal: true

class BacktestJob < ApplicationJob
  include GoodJob::ActiveJobExtensions::Concurrency
  include JobIteration::Iteration

  good_job_control_concurrency_with(
    total_limit: 1,
    key: -> { "#{self.class.name}-#{arguments[0].id.join('-')}" }
  )

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
