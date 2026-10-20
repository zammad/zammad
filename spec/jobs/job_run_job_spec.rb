# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe JobRunJob do
  describe '#perform' do
    let(:job) { create(:job, active: false) }

    before { allow(Job).to receive(:find_by).with(id: job.id).and_return(job) }

    it 'force-runs an inactive job' do
      allow(job).to receive(:run)

      described_class.perform_now(job.id)

      expect(job).to have_received(:run).with(true)
    end

    it 'keeps the job inactive and unscheduled' do
      described_class.perform_now(job.id)

      expect(job.reload).to have_attributes(active: false, next_run_at: nil)
    end

    context 'with an active job that has a time plan' do
      let(:timeplan) { { 'days' => { 'Mon' => true }, 'hours' => { '0' => true }, 'minutes' => { '0' => true } } }
      let(:job)      { create(:job, active: true, timeplan:) }

      before do
        Setting.set('timezone_default', 'UTC')
        travel_to Time.zone.parse('2026-10-18 12:00 UTC')
      end

      it 'keeps the job active with the same time plan' do
        described_class.perform_now(job.id)

        expect(job.reload).to have_attributes(active: true, timeplan:)
      end

      it 'schedules the next run for the next time slot' do
        described_class.perform_now(job.id)

        expect(job.reload.next_run_at).to eq(Time.zone.parse('2026-10-19 00:00 UTC'))
      end
    end

    it 'does not run a job that is already running' do
      job.update_columns(running: true, last_run_at: 1.minute.ago)
      allow(job).to receive(:run)

      described_class.perform_now(job.id)

      expect(job).not_to have_received(:run)
    end

    it 'ignores a deleted job' do
      allow(Job).to receive(:find_by).with(id: 0).and_return(nil)

      expect { described_class.perform_now(0) }.not_to raise_error
    end
  end

  describe 'locking', performs_jobs: true do
    let(:job) { create(:job) }

    it 'enqueues only one run per job' do
      expect { 2.times { described_class.perform_later(job.id) } }
        .to have_enqueued_job(described_class).exactly(:once)
    end
  end
end
