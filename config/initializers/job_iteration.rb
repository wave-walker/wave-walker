# frozen_string_literal: true

JobIteration.max_job_runtime = 5.minutes

module JobIteration
  module InterruptionAdapters
    module GoodJobAdapter
      class << self
        def call
          !!::GoodJob.current_thread_shutting_down?
        end
      end
    end

    register(:good_job, GoodJobAdapter)
  end
end
