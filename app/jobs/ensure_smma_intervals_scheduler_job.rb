# frozen_string_literal: true

class EnsureSmmaIntervalsSchedulerJob < ApplicationJob
  include JobIteration::Iteration

  queue_as :low

  def build_enumerator(cursor:)
    enumerator_builder.active_record_on_records(Strategy.all, cursor:)
  end

  def each_iteration(strategy)
    EnsureSmmaIntervalsJob.perform_later(strategy)
  end
end
