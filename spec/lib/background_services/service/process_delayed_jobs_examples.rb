# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

RSpec.shared_examples 'BackgroundServices::Service delayed jobs pre_run' do |queue:, cleans_up_import_jobs:|
  describe '.pre_run' do
    it 'cleans up DelayedJobs' do
      allow(described_class::CleanupAction).to receive(:cleanup_delayed_jobs)

      described_class.pre_run

      expect(described_class::CleanupAction)
        .to have_received(:cleanup_delayed_jobs)
        .with(anything, queues: contain_exactly(queue))
    end

    it "#{cleans_up_import_jobs ? 'cleans' : 'does not clean'} up ImportJobs" do
      allow(ImportJob).to receive(:cleanup_import_jobs)

      described_class.pre_run

      expect(ImportJob).to have_received(:cleanup_import_jobs).exactly(cleans_up_import_jobs ? 1 : 0).times
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
