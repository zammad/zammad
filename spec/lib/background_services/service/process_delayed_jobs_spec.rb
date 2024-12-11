# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

class SampleDelayedJob < ApplicationJob
  def perform
    Rails.logger.debug 'performing SampleTestJob'
  end
end

RSpec.describe BackgroundServices::Service::ProcessDelayedJobs, ensure_threads_exited: true do
  before do
    stub_const "#{described_class}::SLEEP_IF_EMPTY", 1
  end

  let(:instance) { described_class.new(manager: nil) }

  describe '#run' do
    context 'with a queued job' do
      before do
        Delayed::Job.destroy_all
        SampleDelayedJob.perform_later
      end

      it 'processes a job' do
        expect do
          ensure_block_keeps_running do
            described_class.new(manager: nil).run
          end
        end.to change(Delayed::Job, :count).by(-1)
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
          expect { described_class.new(manager: nil).run }.not_to change(Delayed::Job, :count)
        end
      end
    end
  end

  describe '#process_results' do
    it 'sleeps & loops when no jobs processed', :aggregate_failures do
      allow(Rails.logger).to receive(:debug)
      instance.send(:process_results, [0, 0], 1)

      expect(Rails.logger).to have_received(:debug).with(no_args) do |&block|
        expect(block.call).to match(%r{loop})
      end
    end

    it 'loops immediatelly when there was anything to process', :aggregate_failures do
      allow(Rails.logger).to receive(:debug)
      instance.send(:process_results, [1, 0], 1)

      expect(Rails.logger).to have_received(:debug).with(no_args) do |&block|
        expect(block.call).to match(%r{jobs processed})
      end
    end
  end

  describe '.pre_run' do
    it 'cleans up DelayedJobs' do
      allow(described_class::CleanupAction).to receive(:cleanup_delayed_jobs)
      described_class.pre_run
      expect(described_class::CleanupAction).to have_received(:cleanup_delayed_jobs)
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
