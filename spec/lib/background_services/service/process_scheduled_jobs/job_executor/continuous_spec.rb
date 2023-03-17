# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

class ContinuousSpecExecutor
  def self.execute
    @executions = 0 if @executions.nil?
    @executions += 1
  end

  def self.executions
    @executions || 0
  end
end

RSpec.describe BackgroundServices::Service::ProcessScheduledJobs::JobExecutor::Continuous, ensure_threads_exited: true do

  subject(:instance) { described_class.new(job) }

  let(:job)        { create(:scheduler, period: 0, method: 'ContinuousSpecExecutor.execute') }
  let(:loop_limit) { BackgroundServices::Service::ProcessScheduledJobs::JobExecutor::Continuous::LOOP_LIMIT }

  before { freeze_time }

  describe '.run' do
    context 'with successful jobs' do
      it 'executes the job many times in a row' do
        expect { instance.run }.to change(ContinuousSpecExecutor, :executions).by(loop_limit)
      end

      it 'sleeps after every execution' do
        allow(instance).to receive(:sleep)
        instance.run
        expect(instance).to have_received(:sleep).with(0).exactly(loop_limit).times
      end

      it 'updates last_run time' do
        instance.job.last_run = nil
        expect { instance.run }.to change(instance.job, :last_run).to(Time.current)
      end
    end

    context 'when job is deleted while loop is running' do
      it 'raises error' do
        allow(instance).to receive(:execute)
        job.destroy
        expect { instance.run }
          .to raise_error(BackgroundServices::Service::ProcessScheduledJobs::SchedulerObjectGoneError)
      end
    end
  end

  describe '#reload_job' do
    it 'returns job' do
      expect(instance.send(:reload_job)).to eq job
    end

    it 'raises error if job is no longer present' do
      job.destroy

      expect { instance.send(:reload_job) }
        .to raise_error(BackgroundServices::Service::ProcessScheduledJobs::SchedulerObjectGoneError,
                        %r{Scheduler #{job.name} was removed})
    end
  end
end
