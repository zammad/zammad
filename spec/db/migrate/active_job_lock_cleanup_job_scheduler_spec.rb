# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe ActiveJobLockCleanupJobScheduler, type: :db_migration do

  let(:scheduler_method) { 'ActiveJobLockCleanupJob.perform_now' }

  context 'New system', system_init_done: false do
    it 'has no work to do' do
      expect { migrate }.not_to change { Scheduler.exists?(method: scheduler_method) }.from(true)
    end
  end

  context 'System that is already set up' do

    before do
      Scheduler.find_by(method: scheduler_method).destroy!
    end

    it 'creates Scheduler' do
      expect { migrate }.to change { Scheduler.exists?(method: scheduler_method) }
    end
  end
end
