# frozen_string_literal: true

class EnsureSmmaIntervalsSchedulerJobTest < ActiveJob::TestCase
  test '#perform, enqueues EnsureSmmaIntervalsJob for each strategy' do
    strategies(:default) # ensure at least one strategy exists

    assert_enqueued_with(job: EnsureSmmaIntervalsJob) do
      EnsureSmmaIntervalsSchedulerJob.perform_now
    end
  end
end
