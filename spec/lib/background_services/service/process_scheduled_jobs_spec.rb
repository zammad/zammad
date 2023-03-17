# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe BackgroundServices::Service::ProcessScheduledJobs do
  let(:instance)    { described_class.new }
  let(:scheduler_1) { create(:scheduler, active: true, prio: 5) }
  let(:scheduler_2) { create(:scheduler, active: true, prio: 1) }
  let(:scheduler_3) { create(:scheduler, active: false, prio: 3) }

  before do
    stub_const("#{described_class}::SLEEP_AFTER_JOB_START", 0)
    stub_const("#{described_class}::SLEEP_AFTER_LOOP", 0)

    Scheduler.destroy_all
  end

  describe '#run' do
    it 'keeps running jobs', ensure_threads_exited: true do
      allow(instance).to receive(:run_jobs)
      ensure_block_keeps_running { instance.run }
      expect(instance).to have_received(:run_jobs).at_least(2)
    end
  end

  describe '#run_jobs' do
    let(:log) { [] }

    before do
      allow_any_instance_of(described_class::Manager).to receive(:run) do
        log << :run_called
      end
    end

    it 'runs manager for each active job' do
      scheduler_1

      instance.send(:run_jobs)

      expect(log).to be_one
    end
  end

  describe '#scope' do
    it 'returns active scheduled jobs by priority' do
      scheduler_1 && scheduler_2 && scheduler_3

      expect(instance.send(:scope)).to eq [scheduler_2, scheduler_1]
    end
  end
end
