# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Issue6226AddActiveJobIdToDelayedJobs < ActiveRecord::Migration[8.0]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    add_column :delayed_jobs, :active_job_id, :string
    add_index :delayed_jobs, :active_job_id

    Delayed::Job.reset_column_information

    # Backfill active_job_id for existing jobs so ActiveJobLock#related_job
    # can immediately look them up without relying on `handler LIKE`.
    Delayed::Job.find_each do |job|
      active_job_id = job.active_job_id_from_handler

      next if active_job_id.blank?

      job.update_columns(active_job_id:) # rubocop:disable Rails/SkipsModelValidations
    end
  end
end
