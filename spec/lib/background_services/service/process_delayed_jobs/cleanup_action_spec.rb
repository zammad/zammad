# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

class SampleDelayedJob < ApplicationJob
  def perform
    Rails.logger.debug 'performing SampleDelayedJob'
  end
end

class SampleReschedulableJob < ApplicationJob
  def reschedule?
    true
  end

  def perform
    Rails.logger.debug 'performing SampleReschedulableJob'
  end
end

RSpec.describe BackgroundServices::Service::ProcessDelayedJobs::CleanupAction do
  describe '.cleanup_delayed_jobs' do
    before do
      Delayed::Job.destroy_all

      SampleDelayedJob.perform_later && Delayed::Job.last.update!(locked_at: Time.current)
      travel 10.minutes
      SampleDelayedJob.perform_later && Delayed::Job.last.update!(locked_at: Time.current)

      allow_any_instance_of(described_class).to receive(:cleanup) do
        log << :cleanup_called
      end
    end

    let(:log) { [] }

    it 'processes no jobs with cut off time in the past' do
      described_class.cleanup_delayed_jobs(15.minutes.ago)
      expect(log).to be_empty
    end

    it 'processes only one job with cut off time in the middle' do
      described_class.cleanup_delayed_jobs(5.minutes.ago)
      expect(log).to be_one
    end

    it 'processes two jobs with cut off time in the future' do
      described_class.cleanup_delayed_jobs(5.minutes.from_now)
      expect(log.count).to be(2)
    end
  end

  describe '#cleanup' do
    before do
      Delayed::Job.destroy_all
    end

    let(:latest_job) { Delayed::Job.last }
    let(:instance)   { described_class.new(latest_job) }

    it 'does not cleanup job in a queue' do
      SampleDelayedJob.perform_later

      allow(instance).to receive(:reschedulable?)
      instance.cleanup
      expect(instance).not_to have_received(:reschedulable?)
    end

    it 'destroys non-reschedulable job' do
      SampleDelayedJob.perform_later

      latest_job.update! locked_at: 1.year.ago

      instance.cleanup
      expect(latest_job).to be_destroyed
    end
  end
end
