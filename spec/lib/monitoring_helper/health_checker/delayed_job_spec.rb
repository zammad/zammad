# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

class SampleJob < ApplicationJob
  def perform
    true
  end
end

RSpec.describe MonitoringHelper::HealthChecker::DelayedJob do
  let(:instance) { described_class.new }

  describe '#check_health' do
    before do
      allow(instance).to receive(:failed_jobs)
      allow(instance).to receive(:failed_with_attempts)
      allow(instance).to receive(:total_jobs)

      instance.check_health
    end

    it 'checks failed jobs' do
      expect(instance).to have_received(:failed_jobs)
    end

    it 'checks failed jobs with attempts' do
      expect(instance).to have_received(:failed_with_attempts)
    end

    it 'checks total jobs' do
      expect(instance).to have_received(:total_jobs)
    end
  end

  describe '#scope' do
    it 'returns jobs with attempts' do
      _job1 = Delayed::Job.enqueue(SampleJob.new)

      job2 = Delayed::Job.enqueue(SampleJob.new)
      job2.update!(attempts: 5)

      expect(instance.send(:scope)).to match_array([job2])
    end
  end

  describe '#failed_jobs' do
    before { stub_const("#{described_class}::FAILED_JOBS_THRESHOLD", 5) }

    it 'does nothing if failed jobs are under threshold' do
      3.times { Delayed::Job.enqueue(SampleJob.new).update!(attempts: 5) }

      instance.send(:failed_jobs)

      expect(instance.response.issues).to be_blank
    end

    it 'adds issue if failed jobs over threshold' do
      10.times { Delayed::Job.enqueue(SampleJob.new).update!(attempts: 5) }

      instance.send(:failed_jobs)

      expect(instance.response.issues.first).to eq '10 failing background jobs'
    end
  end

  describe '#failed_with_attempts' do
    it 'adds issue for failed jobs' do
      10.times { Delayed::Job.enqueue(SampleJob.new).update!(attempts: 5) }

      instance.send(:failed_with_attempts)

      expect(instance.response.issues.first).to eq "Failed to run background job #1 'SampleJob' 10 time(s) with 50 attempt(s)."
    end
  end

  describe '#map_single_failed_job' do
    let(:job) { Delayed::Job.enqueue(SampleJob.new) }
    let(:hash) { {} }

    it 'starts collecting with empty hash' do
      job.update! attempts: 3

      instance.send(:map_single_failed_job, job, hash)

      expect(hash).to include('SampleJob' => { count: 1, attempts: 3 })
    end

    it 'adds details to existing hash' do
      job.update! attempts: 3
      hash['SampleJob'] = { count: 3, attempts: 123 }

      instance.send(:map_single_failed_job, job, hash)

      expect(hash).to include('SampleJob' => { count: 4, attempts: 126 })
    end
  end

  describe '#job_name' do
    it 'returns original job class name' do
      job = Delayed::Job.enqueue(SampleJob.new)

      expect(instance.send(:job_name, job)).to eq 'SampleJob'
    end
  end

  describe '#total_jobs' do
    before { stub_const("#{described_class}::TOTAL_JOBS_THRESHOLD", 4) }

    it 'does nothing if jobs count is bellow threshold' do
      6.times { |i| Delayed::Job.enqueue(SampleJob.new).update!(created_at: (i * 4).minutes.ago) }
    end

    it 'adds issue if jobs count is over threshold' do
      10.times { |i| Delayed::Job.enqueue(SampleJob.new).update!(created_at: (i * 4).minutes.ago) }
    end
  end
end
