# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe MonitoringHelper::HealthChecker::ImportJob do
  let(:instance) { described_class.new }
  let(:job)      { create(:import_job, name: :sample, dry_run: false) }

  before do
    allow(ImportJob).to receive(:backends).and_return([:sample])
  end

  describe '#check_health' do
    before do
      allow(instance).to receive(:failed_imports)
      allow(instance).to receive(:stuck_imports)

      instance.check_health
    end

    it 'checks failed imports' do
      expect(instance).to have_received(:failed_imports)
    end

    it 'checks stuck imports' do
      expect(instance).to have_received(:stuck_imports)
    end
  end

  describe '#import_backends' do
    it 'calls ImportJob.backends' do
      instance.send(:import_backends)
      expect(ImportJob).to have_received(:backends)
    end
  end

  describe '#failed_imports' do
    it 'calls single_failed_import' do
      allow(instance).to receive(:single_failed_import)
      instance.send(:failed_imports)
      expect(instance).to have_received(:single_failed_import).with(:sample)
    end
  end

  describe '#failed_import_job' do
    it 'returns failed import' do
      job.update! finished_at: 1.minute.ago
      expect(instance.send(:failed_import_job, :sample)).to eq job
    end

    it 'does not return old finished import' do
      job.update! finished_at: 11.minutes.ago
      expect(instance.send(:failed_import_job, :sample)).to be_nil
    end

    it 'returns nil if no failed mports' do
      expect(instance.send(:failed_import_job, :sample)).to be_nil
    end
  end

  describe '#single_failed_import' do
    it 'does nothing if no failed job' do
      instance.send(:single_failed_import, :sample)
      expect(instance.response.issues).to be_blank
    end

    it 'does nothing if job has no error message' do
      job.update! finished_at: 1.minute.ago
      instance.send(:single_failed_import, :sample)
      expect(instance.response.issues).to be_blank
    end

    it 'adds issue for failed import' do
      job.update! finished_at: 1.minute.ago, result: { error: 'message' }
      instance.send(:single_failed_import, :sample)
      expect(instance.response.issues.first).to start_with('Failed to run').and(end_with('Cause: message'))
    end
  end

  describe '#stuck_imports' do
    it 'calls single_stuck_import' do
      allow(instance).to receive(:single_stuck_import)
      instance.send(:stuck_imports)
      expect(instance).to have_received(:single_stuck_import).with(:sample)
    end
  end

  describe '#stuck_import_job' do
    it 'returns stuck import' do
      job.update! updated_at: 11.minutes.ago
      expect(instance.send(:stuck_import_job, :sample)).to eq job
    end

    it 'does not return just updated import' do
      job.update! updated_at: 1.minute.ago
      expect(instance.send(:stuck_import_job, :sample)).to be_nil
    end

    it 'returns nil if no stuck mports' do
      expect(instance.send(:stuck_import_job, :sample)).to be_nil
    end
  end

  describe '#single_stuck_import' do
    it 'does nothing if no stuck job' do
      instance.send(:single_stuck_import, :sample)
      expect(instance.response.issues).to be_blank
    end

    it 'adds issue for stuck import' do
      allow(instance).to receive(:stuck_import_job).and_return(job)
      instance.send(:single_stuck_import, :sample)
      expect(instance.response.issues.first).to start_with("Stuck import backend 'sample'")
    end
  end
end
