# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe ActiveJobLockCleanupJob, type: :job do

  context 'when ActiveJobLock records older than a day are present' do

    before do
      create(:active_job_lock, created_at: 1.day.ago)
      travel 1.minute
    end

    it 'cleans up those jobs' do
      expect { described_class.perform_now }.to change(ActiveJobLock, :count).by(-1)
    end
  end

  context 'when recent ActiveJobLock records are present' do

    before do
      create(:active_job_lock, created_at: 1.minute.ago)
    end

    it 'keeps those jobs' do
      expect { described_class.perform_now }.not_to change(ActiveJobLock, :count)
    end
  end
end
