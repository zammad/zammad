# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe BackgroundServices::Service::ProcessScheduledJobs::Manager do
  let(:instance) { described_class.new(job, container) }

  let(:container) { Concurrent::Hash.new }
  let(:job)       { create(:scheduler) }

  describe '#run' do
    before do
      allow(instance).to receive(:skip?).and_return(skipping)
      allow(instance).to receive(:start).and_return(:thread)
    end

    context 'when #skip? returns false' do
      let(:skipping) { false }

      it 'starts job' do
        instance.run
        expect(instance).to have_received(:start)
      end

      it 'adds job to container' do
        instance.run
        expect(container).to include(job.id => :thread)
      end
    end

    context 'when #skip? returns true' do
      let(:skipping) { true }

      it 'skips job' do
        instance.run
        expect(instance).not_to have_received(:start)
      end
    end
  end

  describe '#skip?' do
    let(:skipping_already_running) { false }
    let(:skipping_job_last_run)    { false }
    let(:skipping_job_timeplan)    { false }

    before do
      allow(instance).to receive(:skip_already_running?).and_return(skipping_already_running)
      allow(instance).to receive(:skip_job_last_run?).and_return(skipping_job_last_run)
      allow(instance).to receive(:skip_job_timeplan?).and_return(skipping_job_timeplan)
    end

    it 'does not skip' do
      expect(instance.send(:skip?)).to be_falsey
    end

    context 'when already running' do
      let(:skipping_already_running) { true }

      it 'skips' do
        expect(instance.send(:skip?)).to be_truthy
      end
    end

    context 'when last run was recent' do
      let(:skipping_job_last_run) { true }

      it 'skips' do
        expect(instance.send(:skip?)).to be_truthy
      end
    end

    context 'when timeplan is ok' do
      let(:skipping_job_timeplan) { true }

      it 'skips' do
        expect(instance.send(:skip?)).to be_truthy
      end
    end
  end

  describe '#skip_already_running?' do
    it 'not skip if no thread' do
      expect(instance.send(:skip_already_running?)).to be_falsey
    end

    it 'not skip if no valid thread' do
      container[job.id] = :asd
      expect(instance.send(:skip_already_running?)).to be_falsey
    end

    it 'skip if alive thread', ensure_threads_exited: true do
      thread = Thread.new { sleep 1000 } # will be stopped by ensure_threads_exited
      container[job.id] = thread
      expect(instance.send(:skip_already_running?)).to be_truthy
    end

    it 'not skip if dead thread', ensure_threads_exited: true do
      thread = Thread.new { 'do nothing' }
      container[job.id] = thread
      expect(instance.send(:skip_already_running?)).to be_falsey
    end
  end

  describe '#skip_job_last_run?' do
    it 'returns false if last run is not logged' do
      job.last_run = nil
      expect(instance.send(:skip_job_last_run?)).to be_falsey
    end

    it 'returns false if last run is long ago' do
      job.last_run = 1.year.ago
      expect(instance.send(:skip_job_last_run?)).to be_falsey
    end

    it 'returns true if last run is recent' do
      job.last_run = 5.minutes.ago
      expect(instance.send(:skip_job_last_run?)).to be_truthy
    end
  end

  describe '#skip_job_timeplan?' do
    it 'not skip if no timeplan' do
      job.timeplan = nil
      expect(instance.send(:skip_job_timeplan?)).to be_falsey
    end

    it 'skip if does not match timeplan' do
      travel_to Time.current.noon
      job.timeplan = timeplan(hour: 10)

      expect(instance.send(:skip_job_timeplan?)).to be_truthy
    end

    it 'not skip if match timeplan' do
      travel_to Time.current.noon
      job.timeplan = timeplan(hour: 12)

      expect(instance.send(:skip_job_timeplan?)).to be_falsey
    end

    def timeplan(hour:)
      {
        days:    { Mon: true, Tue: true, Wed: true, Thu: true, Fri: true, Sat: true, Sun: true },
        hours:   { hour => true },
        minutes: { 0 => true }
      }
    end
  end

  describe '#start', ensure_threads_exited: true do
    it 'starts a thread' do
      container[job.id] = :thread
      allow(instance).to receive(:start_in_thread).and_invoke(-> { sleep 1000 }) # will be stopped by ensure_threads_exited

      thread = instance.send(:start)
      expect(thread).to be_alive
    end

    it 'clears job from job container if error was raised in the job' do
      container[job.id] = :thread
      allow(instance).to receive(:start_in_thread).and_raise('error')
      thread = instance.send(:start)
      thread.join

      expect(container).not_to include(job.id => :thread)
    end

    it 'does not bubble up error if raised' do
      allow(BackgroundServices::Service::ProcessScheduledJobs::JobExecutor).to receive(:run).and_raise('error')

      thread = instance.send(:start)
      thread.join

      expect { instance.send(:start) }.not_to raise_error
    end
  end

  describe '#start_in_thread' do
    it 'launches job in scheduler context' do
      handle_info = nil
      allow(BackgroundServices::Service::ProcessScheduledJobs::JobExecutor)
        .to receive(:run).and_invoke(->(_) { handle_info = ApplicationHandleInfo.current })
      instance.send(:start_in_thread)

      expect(handle_info).to eq 'scheduler'
    end

    it 'wraps up after job' do
      allow(BackgroundServices::Service::ProcessScheduledJobs::JobExecutor).to receive(:run)

      allow(instance).to receive(:wrapup)
      instance.send(:start_in_thread)

      expect(instance).to have_received(:wrapup)
    end

    it 'does not wrap up after job with error' do
      allow(BackgroundServices::Service::ProcessScheduledJobs::JobExecutor).to receive(:run).and_raise('error')

      allow(instance).to receive(:wrapup)

      instance.send(:start_in_thread) rescue nil # rubocop:disable Style/RescueModifier

      expect(instance).not_to have_received(:wrapup)
    end
  end

  describe '#wrapup' do
    context 'when job present' do
      it 'clears pid' do
        expect { instance.send(:wrapup) }.to change { job.reload.pid }.to('')
      end

      it 'removes job from the jobs container' do
        container[job.id] = :sample
        expect { instance.send(:wrapup) }.to change(instance, :thread).to(nil)
      end
    end
  end

  describe '#invalid_thread_log' do
    it 'logs to error log' do
      allow(instance).to receive(:build_invalid_thread_log).and_return('sample error')
      allow(Rails.logger).to receive(:error)

      instance.send(:invalid_thread_log, :thread, :status)

      expect(Rails.logger).to have_received(:error).with('sample error')
    end
  end

  describe '#build_invalid_thread_log' do
    it 'declare thread status for a valid thread', ensure_threads_exited: true do
      thread = Thread.new { 'do nothing' }

      expect(instance.send(:build_invalid_thread_log, thread, 'test')).to match %r{^Invalid thread stored}
    end

    it 'declare unknown when status is given, but thread not given' do
      expect(instance.send(:build_invalid_thread_log, nil, 'test')).to match %r{^Job thread terminated unknownly}
    end

    it 'declare normal when status is false and thread not given' do
      expect(instance.send(:build_invalid_thread_log, nil, false)).to match %r{^Job thread terminated normally}
    end

    it 'declare normal when status is missing and thread not given' do
      expect(instance.send(:build_invalid_thread_log, nil, nil)).to match %r{^Job thread terminated via an exception}
    end
  end
end
