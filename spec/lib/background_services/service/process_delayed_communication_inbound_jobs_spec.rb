# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'lib/background_services/service/process_delayed_jobs_examples'

RSpec.describe BackgroundServices::Service::ProcessDelayedCommunicationInboundJobs, :aggregate_failures, ensure_threads_exited: true do
  before do
    stub_const "#{described_class}::SLEEP_IF_EMPTY", 1
    stub_const 'SampleDelayedJob', Class.new(ApplicationJob) { def perform; end }
    stub_const 'SampleDelayedCommunicationInboundJob', Class.new(ApplicationJob) {
      queue_as :communication_inbound

      def perform; end
    }
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

  it_behaves_like 'BackgroundServices::Service delayed jobs pre_run', queue: :communication_inbound, cleans_up_import_jobs: false
end
