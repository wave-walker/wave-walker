# frozen_string_literal: true

class RemoveGoodjob < ActiveRecord::Migration[8.0]
  def up
    drop_table :good_job_batches
    drop_table :good_job_executions
    drop_table :good_job_processes
    drop_table :good_job_settings
    drop_table :good_jobs
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
