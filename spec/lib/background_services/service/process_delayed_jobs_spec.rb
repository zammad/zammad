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

RSpec.describe BackgroundServices::Service::ProcessDelayedJobs, :aggregate_failures, ensure_threads_exited: true do
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

      it 'processes the default job, but not the AI job' do
        expect do
          ensure_block_keeps_running do
            described_class.new(manager:).run
          end
        end.to change(Delayed::Job, :count).by(-1)
        expect(Delayed::Job.last.queue).to eq 'ai'
      end

      it 'runs loop multiple times', :aggregate_failures do
        allow(instance).to receive(:process_results)
        # Delayed::Worker uses `rescue Exception` heavily which would swallow our timeout errors,
        #   causing the tests to fail. Avoid calling it.
        allow(Benchmark).to receive(:realtime).and_return(1)

        ensure_block_keeps_running { instance.run }

        expect(instance).to have_received(:process_results).at_least(1)
      end

      context 'when shutdown is requested' do
        before do
          allow(BackgroundServices).to receive(:shutdown_requested).and_return(true)
        end

        it 'does not start jobs' do
          expect { described_class.new(manager:).run }.not_to change(Delayed::Job, :count)
        end
      end
    end
  end

  describe '#process_results' do
    before do
      allow(instance).to receive(:process_empty).and_call_original
      allow(instance).to receive(:process_busy).and_call_original
      allow(instance).to receive(:interruptible_sleep)
    end

    it 'sleeps & loops when no jobs processed', :aggregate_failures do
      instance.send(:process_results, [0, 0], 1)

      expect(instance).to have_received(:process_empty)
      expect(instance).to have_received(:interruptible_sleep)
    end

    it 'loops immediately when there was anything to process', :aggregate_failures do
      instance.send(:process_results, [1, 0], 1)

      expect(instance).to have_received(:process_busy).with([1, 0], 1)
      expect(instance).not_to have_received(:interruptible_sleep)
    end

    it 'loops immediately when all processed jobs failed', :aggregate_failures do
      instance.send(:process_results, [0, 123], 1)

      expect(instance).to have_received(:process_busy).with([0, 123], 1)
      expect(instance).not_to have_received(:interruptible_sleep)
    end
  end

  describe '.pre_run' do
    it 'cleans up DelayedJobs' do
      allow(described_class::CleanupAction).to receive(:cleanup_delayed_jobs)

      described_class.pre_run

      expect(described_class::CleanupAction)
        .to have_received(:cleanup_delayed_jobs)
        .with(anything, queues: contain_exactly(:default))
    end

    it 'cleans up ImportJobs' do
      allow(ImportJob).to receive(:cleanup_import_jobs)
      described_class.pre_run
      expect(ImportJob).to have_received(:cleanup_import_jobs)
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
