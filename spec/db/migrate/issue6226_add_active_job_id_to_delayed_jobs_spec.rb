# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Issue6226AddActiveJobIdToDelayedJobs, db_strategy: :reset, type: :db_migration do
  let(:job_id) { SecureRandom.uuid }

  let(:active_job_handler) do
    ActiveJob::QueueAdapters::DelayedJobAdapter::JobWrapper.new(
      'job_class' => 'ApplicationJob',
      'job_id'    => job_id,
      'arguments' => [],
    ).to_yaml
  end

  let(:legacy_handler) { { legacy: true }.to_yaml }

  before do
    # Simulate the pre-migration schema and insert rows the way it would
    # have looked like before `active_job_id` existed (bypassing callbacks
    # and validations, since #insert! works on the raw DB table).
    without_column :delayed_jobs, column: :active_job_id

    Delayed::Job.reset_column_information

    Delayed::Job.insert!({ handler: active_job_handler, run_at: Time.current, created_at: Time.current, updated_at: Time.current })
    Delayed::Job.insert!({ handler: legacy_handler, run_at: Time.current, created_at: Time.current, updated_at: Time.current })
  end

  it 'adds the active_job_id column' do
    expect { migrate }
      .to change { column_exists?(:delayed_jobs, :active_job_id) }.from(false).to(true)
  end

  it 'adds an index on active_job_id' do
    expect { migrate }
      .to change { index_exists?(:delayed_jobs, :active_job_id) }.from(false).to(true)
  end

  it 'backfills active_job_id for jobs with an ActiveJob handler' do
    migrate

    Delayed::Job.reset_column_information

    expect(Delayed::Job.find_by(handler: active_job_handler).active_job_id).to eq(job_id)
  end

  it 'leaves active_job_id blank for jobs without an ActiveJob handler' do
    migrate

    Delayed::Job.reset_column_information

    expect(Delayed::Job.find_by(handler: legacy_handler).active_job_id).to be_nil
  end
end
