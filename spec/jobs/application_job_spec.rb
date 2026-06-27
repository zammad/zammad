# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

class FailingTestJob < ApplicationJob
  retry_on(StandardError, attempts: 5)

  def perform
    Rails.logger.debug 'Failing'
    raise 'Some error...'
  end
end

class SampleLoggingTestJob < ApplicationJob
  def perform; end
end

class SampleLockedLoggingTestJob < ApplicationJob
  include HasActiveJobLock

  def perform; end
end

RSpec.describe ApplicationJob do

  it 'syncs ActiveJob#executions to Delayed::Job#attempts' do
    FailingTestJob.perform_later
    expect { Delayed::Worker.new.work_off }.to change { Delayed::Job.last.attempts }
  end

  describe 'logging' do
    let(:log_output)   { StringIO.new }
    let(:logger_level) { Logger::INFO }
    let(:test_logger) do
      Logger.new(log_output).tap { |logger| logger.level = logger_level }
    end

    around do |example|
      original_rails_logger = Rails.logger
      original_active_job_logger = ActiveJob::Base.logger
      original_delayed_logger = Delayed::Worker.logger

      Rails.logger = test_logger
      ActiveJob::Base.logger = test_logger
      Delayed::Worker.logger = test_logger

      example.run
    ensure
      Rails.logger = original_rails_logger
      ActiveJob::Base.logger = original_active_job_logger
      Delayed::Worker.logger = original_delayed_logger
    end

    context 'with logger at info level' do
      it 'does not emit ActiveJob lifecycle log lines', :aggregate_failures do
        SampleLoggingTestJob.perform_later
        Delayed::Worker.new.work_off

        expect(log_output.string).not_to include('Enqueued')
        expect(log_output.string).not_to include('Performing')
        expect(log_output.string).not_to include('Performed')
      end

      it 'does not emit DelayedJob per-job lifecycle log lines', :aggregate_failures do
        SampleLoggingTestJob.perform_later
        Delayed::Worker.new.work_off

        expect(log_output.string).not_to include('RUNNING')
        expect(log_output.string).not_to include('COMPLETED')
      end

      it 'still emits error-level ActiveJob lines (e.g. retry_stopped)' do
        # Trigger the `retry_stopped.active_job` notification directly so we
        #   don't have to actually run a job through five retry cycles.
        ActiveSupport::Notifications.instrument(
          'retry_stopped.active_job',
          job:   SampleLoggingTestJob.new,
          error: StandardError.new('boom'),
        )

        expect(log_output.string).to include('Stopped retrying SampleLoggingTestJob')
      end
    end

    context 'with logger at debug level' do
      let(:logger_level) { Logger::DEBUG }

      it 'still emits ActiveJob lifecycle log lines for visibility in development', :aggregate_failures do
        SampleLoggingTestJob.perform_later
        Delayed::Worker.new.work_off

        expect(log_output.string).to include('Enqueued')
        expect(log_output.string).to include('Performed')
      end

      # Positive counterpart to the info-level test above. If DelayedJob ever
      #   renames the per-job RUNNING / COMPLETED messages, this test fails
      #   and signals that the `job_say` override needs updating.
      it 'emits DelayedJob per-job lifecycle log lines', :aggregate_failures do
        SampleLoggingTestJob.perform_later
        Delayed::Worker.new.work_off

        expect(log_output.string).to include('RUNNING')
        expect(log_output.string).to include('COMPLETED')
      end

      it 'emits a "Won\'t enqueue" line when a HasActiveJobLock collision happens' do
        SampleLockedLoggingTestJob.perform_later
        SampleLockedLoggingTestJob.perform_later

        expect(log_output.string).to include("Won't enqueue SampleLockedLoggingTestJob")
      end
    end
  end
end
