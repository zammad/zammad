# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe MonitoringHelper::HealthChecker::Scheduler do
  let(:instance) { described_class.new }

  describe '#check_health' do
    before do
      allow(instance).to receive(:last_execution)
      allow(instance).to receive(:none_running)
      allow(instance).to receive(:failed_jobs)

      instance.check_health
    end

    it 'checks last_execution' do
      expect(instance).to have_received(:last_execution)
    end

    it 'checks none_running' do
      expect(instance).to have_received(:none_running)
    end

    it 'checks failed_jobs' do
      expect(instance).to have_received(:failed_jobs)
    end
  end

  describe '#last_execution' do
    it 'does nothing if no schedulers active' do
      allow(instance).to receive(:last_execution_scope).and_return([])
      instance.send(:last_execution)
      expect(instance.response.issues).to be_blank
    end

    it 'does nothing if schedulers are on time' do
      scheduler = create(:scheduler, last_run: 5.minutes.ago)
      allow(instance).to receive(:last_execution_scope).and_return([scheduler])
      instance.send(:last_execution)
      expect(instance.response.issues).to be_blank
    end

    it 'adds issue if scheduler is late' do
      scheduler = create(:scheduler, last_run: 50.minutes.ago)
      allow(instance).to receive(:last_execution_scope).and_return([scheduler])
      instance.send(:last_execution)
      expect(instance.response.issues.first).to start_with('scheduler may not run')
    end

    it 'adds single issue if multiple schedulers are late' do
      scheduler = create(:scheduler, last_run: 50.minutes.ago)
      scheduler2 = create(:scheduler, last_run: 30.minutes.ago)
      allow(instance).to receive(:last_execution_scope).and_return([scheduler, scheduler2])
      instance.send(:last_execution)
      expect(instance.response.issues.count).to be 1
    end
  end

  describe '#last_execution_scope' do
    it 'returns active schedulers with last run timestamp' do
      Scheduler.destroy_all

      _scheduler = create(:scheduler, last_run: nil)
      scheduler2 = create(:scheduler, last_run: 30.minutes.ago)
      _scheduler3 = create(:scheduler, last_run: 30.minutes.ago, active: false)

      expect(instance.send(:last_execution_scope)).to eq [scheduler2]
    end
  end

  describe '#last_execution_on_time?' do
    it 'returns true if scheduler is within execution tolerance' do
      scheduler = create(:scheduler, last_run: 5.minutes.ago)
      expect(instance.send(:last_execution_on_time?, scheduler)).to be_truthy
    end

    it 'returns true if last run is beyond execution tolerance but period moves it within' do
      scheduler = create(:scheduler, last_run: 15.minutes.ago)
      expect(instance.send(:last_execution_on_time?, scheduler)).to be_truthy
    end

    it 'returns false if scheduler is beyond execution tolerance' do
      scheduler = create(:scheduler, last_run: 50.minutes.ago)
      expect(instance.send(:last_execution_on_time?, scheduler)).to be_falsey
    end

    context 'with timeplan' do
      it 'returns true if timeplan scheduler was not skipped' do
        travel_to Time.current.beginning_of_day
        scheduler = create(:scheduler, :timeplan, last_run: 55.minutes.ago)
        expect(instance.send(:last_execution_on_time?, scheduler)).to be_truthy
      end

      # https://github.com/zammad/zammad/issues/4079
      it 'returns true if timeplan scheduler was slightly late only' do
        travel_to Time.current.beginning_of_day - 10.minutes
        scheduler = create(:scheduler, :timeplan, last_run: 6.hours.ago)
        expect(instance.send(:last_execution_on_time?, scheduler)).to be_truthy
      end

      it 'returns true if timeplan scheduler was skipped once' do
        travel_to Time.current.noon
        scheduler = create(:scheduler, :timeplan, last_run: 1.day.ago)
        expect(instance.send(:last_execution_on_time?, scheduler)).to be_truthy
      end

      it 'returns false if timeplan scheduler was skipped twice' do
        travel_to Time.current.noon
        scheduler = create(:scheduler, :timeplan, last_run: 2.days.ago)
        expect(instance.send(:last_execution_on_time?, scheduler)).to be_falsey
      end
    end
  end

  describe '#none_running' do
    it 'does nothing if any schedulers were run' do
      Scheduler.all.sample.update! last_run: Time.current
      instance.send(:none_running)
      expect(instance.response.issues).to be_blank
    end

    it 'adds issue if no schedulers were run' do
      Scheduler.update_all last_run: nil
      instance.send(:none_running)
      expect(instance.response.issues.first).to eq 'scheduler not running'
    end
  end

  describe '#failed_jobs' do
    it 'does nothing if no failed jobs' do
      allow(Scheduler).to receive(:failed_jobs).and_return([])
      instance.send(:failed_jobs)
      expect(instance.response.issues).to be_blank
    end

    context 'with a failed job' do
      let(:scheduler) { create(:scheduler) }

      before do
        allow(Scheduler).to receive(:failed_jobs).and_return([scheduler])
        instance.send(:failed_jobs)
      end

      it 'adds issue' do
        expect(instance.response.issues.first).to start_with('Failed to run')
      end

      it 'adds action' do
        expect(instance.response.actions.first).to eq :restart_failed_jobs
      end
    end
  end
end
