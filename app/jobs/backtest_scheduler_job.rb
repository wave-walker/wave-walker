# frozen_string_literal: true

class BacktestSchedulerJob < ApplicationJob
  include JobIteration::Iteration

  queue_as :low

  def build_enumerator(cursor:)
    enumerator_builder.active_record_on_records(
      Backtest.all,
      cursor:
    )
  end

  def each_iteration(backtest)
    BacktestJob.perform_later(backtest)
  end
end
