# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'lib/background_services/service/process_delayed_jobs_examples'

RSpec.describe BackgroundServices::Service::ProcessDelayedAIJobs, :aggregate_failures, ensure_threads_exited: true do
  before do
    stub_const "#{described_class}::SLEEP_IF_EMPTY", 1
    stub_const 'SampleDelayedJob', Class.new(ApplicationJob) { def perform; end }
    stub_const 'SampleDelayedAIJob', Class.new(AIJob) { def perform; end }
    # This job does not finish so that we can test the job scheduling.
    stub_const 'SampleDelayedPendingAIJob', Class.new(AIJob) { def perform = sleep(100) }
  end

  let(:manager)  { BackgroundServices.new(BackgroundServices::ServiceConfig.configuration_from_env({})) }
  let(:instance) { described_class.new(manager:) }

  describe '#run' do
    context 'with a queued job' do
      before do
        Delayed::Job.destroy_all
        SampleDelayedJob.perform_later
        SampleDelayedAIJob.perform_later
      end

      it 'processes the AI job, but not the default job' do
        expect do
          ensure_block_keeps_running do
            described_class.new(manager:).run
          end
        end.to change(Delayed::Job, :count).by(-1)
        expect(Delayed::Job.last.queue).to eq 'default'
      end
    end

    context 'with multiple threads' do
      before do
        10.times { SampleDelayedPendingAIJob.perform_later }
      end

      # 5 threads are the default setting for this service
      it 'schedules one job per thread' do
        ensure_block_keeps_running do
          described_class.new(manager:).run
        end
        # Creates 10 jobs in total
        expect(Delayed::Job.where(queue: 'ai').count).to eq 10
        # 5 are not assigned to a thread yet
        expect(Delayed::Job.where(queue: 'ai', locked_by: nil).count).to eq 5
        # 5 are assigned to a different thread each - but not more
        expect(Delayed::Job.where(queue: 'ai').where.not(locked_by: nil).pluck(:locked_by).uniq.count).to eq 5
      end
    end
  end

  it_behaves_like 'BackgroundServices::Service delayed jobs pre_run', queue: :ai, cleans_up_import_jobs: false
end
