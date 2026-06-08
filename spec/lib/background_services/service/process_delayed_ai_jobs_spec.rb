# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

class SampleDelayedJob < ApplicationJob
  def perform
    Rails.logger.debug 'performing SampleTestJob'
  end
end

class SampleDelayedAIJob < AIJob
  def perform
    Rails.logger.debug 'performing SampleTestAIJob'
  end
end

# This job does not finish so that we can test the job scheduling.
class SampleDelayedPendingAIJob < AIJob
  def perform
    Rails.logger.debug 'performing SampleTestAIJob'
    sleep 100
  end
end

RSpec.describe BackgroundServices::Service::ProcessDelayedAIJobs, :aggregate_failures, ensure_threads_exited: true do
  before do
    stub_const "#{described_class}::SLEEP_IF_EMPTY", 1
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

  describe '.pre_run' do
    it 'cleans up DelayedJobs' do
      allow(described_class::CleanupAction).to receive(:cleanup_delayed_jobs)

      described_class.pre_run

      expect(described_class::CleanupAction)
        .to have_received(:cleanup_delayed_jobs)
        .with(anything, queues: contain_exactly(:ai))
    end

    it 'does not clean up ImportJobs' do
      allow(ImportJob).to receive(:cleanup_import_jobs)
      described_class.pre_run
      expect(ImportJob).not_to have_received(:cleanup_import_jobs)
    end

    it 'runs in scheduler context' do
      handle_info = nil
      allow(described_class)
        .to receive(:pre_launch).and_invoke(-> { handle_info = ApplicationHandleInfo.current })

      described_class.pre_run

      expect(handle_info).to eq 'scheduler'
    end
  end
end
