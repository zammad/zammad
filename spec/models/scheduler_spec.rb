# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'models/concerns/has_xss_sanitized_note_examples'
require 'models/concerns/has_timeplan_examples'

RSpec.describe Scheduler do

  let!(:failed_job) { create(:scheduler, status: 'error', active: false) }

  it_behaves_like 'HasXssSanitizedNote', model_factory: :scheduler
  it_behaves_like 'HasTimeplan'

  describe '.failed_jobs' do
    it 'does list failed jobs' do
      expect(described_class.failed_jobs).to include(failed_job)
    end
  end

  describe '.restart_failed_jobs' do
    it 'does restart failed jobs' do
      described_class.restart_failed_jobs
      expect(failed_job.reload.active).to be true
    end
  end

  describe '.runs_as_persistent_loop?' do
    context 'when job is default' do
      let(:job) { create(:scheduler) }

      it 'does not run as loop' do
        expect(job.runs_as_persistent_loop?).to be false
      end
    end

    context 'when job period is > 5 min' do
      let(:job) { create(:scheduler, period: 6.minutes) }

      it 'does run as loop' do
        expect(job.runs_as_persistent_loop?).to be false
      end
    end

    context 'when job period is <= 5 min' do
      let(:job) { create(:scheduler, period: 5.minutes) }

      it 'does run as loop' do
        expect(job.runs_as_persistent_loop?).to be true
      end
    end
  end
end
