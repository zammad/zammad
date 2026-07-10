# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

class FailingTestJob < ApplicationJob
  retry_on(StandardError, attempts: 5)

  def perform
    Rails.logger.debug 'Failing'
    raise 'Some error...'
  end
end

class SampleLoggingTestJob < ApplicationJob
  def perform; end
end

RSpec.describe ApplicationJob do

  it 'syncs ActiveJob#executions to Delayed::Job#attempts' do
    FailingTestJob.perform_later
    expect { Delayed::Worker.new.work_off }.to change { Delayed::Job.last.attempts }
  end

  describe 'Delayed::Job#active_job_id' do
    it 'is set to the ActiveJob job_id for ActiveJob-backed jobs' do
      job = SampleLoggingTestJob.perform_later

      expect(Delayed::Job.last.active_job_id).to eq(job.job_id)
    end

    it 'is not changed when unrelated attributes are updated' do
      SampleLoggingTestJob.perform_later
      delayed_job = Delayed::Job.last

      expect { delayed_job.update!(locked_by: 'worker-1') }
        .not_to change(delayed_job, :active_job_id)
    end

    it 'is blank for Delayed::Job entries not backed by an ActiveJob' do
      delayed_job = Delayed::Job.enqueue(Delayed::PerformableMethod.new(Object.new, :to_s, []))

      expect(delayed_job.active_job_id).to be_nil
    end

    it 'is blank when the handler cannot be deserialized' do
      delayed_job = Delayed::Job.create!(handler: '{invalid_yaml:', run_at: Time.current)

      expect(delayed_job.active_job_id).to be_nil
    end
  end

  describe '.job_by_active_job_id' do
    context 'when using a Delayed::Job adapter' do
      it 'returns the Delayed::Job record for the given ActiveJob job_id' do
        job = SampleLoggingTestJob.perform_later

        expect(described_class.job_by_active_job_id(job.job_id)).to eq(Delayed::Job.last)
      end

      it 'returns nil if no Delayed::Job record exists for the given ActiveJob job_id' do
        expect(described_class.job_by_active_job_id('nonexistent_job_id')).to be_nil
      end

      context 'when active_job_id column is not present' do
        around do |example|
          ActiveRecord::Migration.remove_column :delayed_jobs, :active_job_id
          Delayed::Job.reset_column_information

          example.run
        ensure
          ActiveRecord::Migration.add_column :delayed_jobs, :active_job_id, :string
          ActiveRecord::Migration.add_index :delayed_jobs, :active_job_id
          Delayed::Job.reset_column_information
        end

        it 'returns the Delayed::Job record for the given ActiveJob job_id' do
          job = SampleLoggingTestJob.perform_later

          expect(described_class.job_by_active_job_id(job.job_id)).to eq(Delayed::Job.last)
        end

        it 'returns nil if no Delayed::Job record exists for the given ActiveJob job_id' do
          expect(described_class.job_by_active_job_id('nonexistent_job_id')).to be_nil
        end
      end
    end

    context 'when using a test adapter', performs_jobs: true do
      it 'returns the enqueued job hash for the given ActiveJob job_id' do
        job = SampleLoggingTestJob.perform_later

        expect(described_class.job_by_active_job_id(job.job_id)).to eq(ActiveJob::Base.queue_adapter.enqueued_jobs.last)
      end

      it 'returns nil if no enqueued job exists for the given ActiveJob job_id' do
        expect(described_class.job_by_active_job_id('nonexistent_job_id')).to be_nil
      end
    end
  end
end
