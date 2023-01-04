# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

class OneTimeSpecExecutor
  def self.execute
    @executions = 0 if @executions.nil?
    @executions += 1
  end

  def self.executions
    @executions || 0
  end
end

RSpec.describe BackgroundServices::Service::ProcessScheduledJobs::JobExecutor::OneTime, ensure_threads_exited: true do

  subject(:instance) { described_class.new(job) }

  let(:job) { create(:scheduler, method: 'OneTimeSpecExecutor.execute') }

  before { freeze_time }

  describe '.run' do
    context 'with successful jobs' do
      it 'executes the job' do
        expect { instance.run }.to change(OneTimeSpecExecutor, :executions).by(1)
      end

      it 'updates last_run time' do
        instance.job.last_run = nil
        expect { instance.run }.to change(instance.job, :last_run).to(Time.current)
      end
    end

    context 'with jobs failing only once' do
      let(:job) { create(:scheduler, method: '@try_count == 0 ? raise : OneTimeSpecExecutor.execute') }

      it 'executes the job' do
        expect { instance.run }.to change(OneTimeSpecExecutor, :executions).by(1)
      end

      it 'had to retry' do
        expect { instance.run }.to change(instance, :try_count).by(1)
      end
    end

    context 'with permanently failing jobs' do
      let(:job) { create(:scheduler, method: 'Call.a.nonexisting_method') }

      it 'causes an exception' do
        expect { instance.run }.to raise_exception BackgroundServices::Service::ProcessScheduledJobs::RetryLimitReachedError
      end

      it 'used all retries' do
        expect do
          instance.run
        rescue BackgroundServices::Service::ProcessScheduledJobs::RetryLimitReachedError
          # Ignore for this test.
        end.to change(instance, :try_count).by(BackgroundServices::Service::ProcessScheduledJobs::JobExecutor::TRY_COUNT_MAX + 1)
      end
    end
  end

end
