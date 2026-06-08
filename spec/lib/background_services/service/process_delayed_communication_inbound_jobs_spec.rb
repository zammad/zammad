# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

class SampleDelayedJob < ApplicationJob
  def perform
    Rails.logger.debug 'performing SampleTestJob'
  end
end

class SampleDelayedCommunicationInboundJob < ApplicationJob
  queue_as :communication_inbound

  def perform
    Rails.logger.debug 'performing SampleTestCommunicationInboundJob'
  end
end

RSpec.describe BackgroundServices::Service::ProcessDelayedCommunicationInboundJobs, :aggregate_failures, ensure_threads_exited: true do
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
        SampleDelayedCommunicationInboundJob.perform_later
      end

      it 'processes the Communication Inbound job, but not the default job' do
        expect do
          ensure_block_keeps_running do
            described_class.new(manager:).run
          end
        end.to change(Delayed::Job, :count).by(-1)
        expect(Delayed::Job.last.queue).to eq 'default'
      end
    end
  end

  describe '.pre_run' do
    it 'cleans up DelayedJobs' do
      allow(described_class::CleanupAction).to receive(:cleanup_delayed_jobs)

      described_class.pre_run

      expect(described_class::CleanupAction)
        .to have_received(:cleanup_delayed_jobs)
        .with(anything, queues: contain_exactly(:communication_inbound))
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
