# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'
require 'models/concerns/has_xss_sanitized_note_examples'

RSpec.describe Scheduler do

  let(:test_backend_class) do
    Class.new do
      def self.start
        # noop
      end

      # rubocop:disable Style/TrivialAccessors
      def self.reschedule=(reschedule)
        @reschedule = reschedule
      end
      # rubocop:enable Style/TrivialAccessors

      def self.reschedule?(_delayed_job)
        @reschedule || false
      end
    end
  end
  let(:test_backend_name) { 'SpecSpace::DelayedJobBackend' }

  before do
    stub_const test_backend_name, test_backend_class
  end

  it_behaves_like 'HasXssSanitizedNote', model_factory: :scheduler

  describe '.failed_jobs' do

    it 'does list failed jobs' do
      job = create(:scheduler, status: 'error', active: false)
      failed_list = described_class.failed_jobs
      expect(failed_list).to be_present
      expect(failed_list).to include(job)
    end

  end

  describe '.restart_failed_jobs' do

    it 'does restart failed jobs' do
      job = create(:scheduler, status: 'error', active: false)
      described_class.restart_failed_jobs
      job.reload
      expect(job.active).to be true
    end
  end

  describe '._start_job' do

    it 'sets error status/message for failed jobs' do
      job = create(:scheduler)
      described_class._start_job(job)
      expect(job.status).to eq 'error'
      expect(job.active).to be false
      expect(job.error_message).to be_present
    end

    it 'executes job that is expected to succeed' do
      expect(Setting).to receive(:reload)
      job = create(:scheduler, method: 'Setting.reload')
      described_class._start_job(job)
      expect(job.status).to eq 'ok'
    end
  end

  describe '.cleanup' do

    it 'gets called by .threads' do
      allow(described_class).to receive(:cleanup).and_throw(:called)
      expect do
        described_class.threads
      end.to throw_symbol(:called)
    end

    context 'not called from .threads method' do

      it 'throws an exception' do
        expect do
          described_class.cleanup
        end.to raise_error(RuntimeError)
      end

      it 'throws no exception with force parameter' do
        expect do
          described_class.cleanup(force: true)
        end.not_to raise_error
      end
    end

    # helpers to avoid the throwing behaviour "describe"d above
    def simulate_threads_call
      threads
    end

    def threads
      described_class.cleanup
    end

    context 'Delayed::Job' do

      it 'keeps unlocked' do
        # meta :)
        described_class.delay.cleanup

        expect do
          simulate_threads_call
        end.not_to change {
          Delayed::Job.count
        }
      end

      context 'locked' do

        it 'gets destroyed' do
          # meta :)
          described_class.delay.cleanup

          # lock job (simluates interrupted scheduler task)
          locked_job = Delayed::Job.last
          locked_job.update!(locked_at: Time.zone.now)

          expect do
            simulate_threads_call
          end.to change {
            Delayed::Job.count
          }.by(-1)
        end

        context 'respond to reschedule?' do

          it 'gets rescheduled for positive responses' do
            SpecSpace::DelayedJobBackend.reschedule = true
            SpecSpace::DelayedJobBackend.delay.start

            # lock job (simluates interrupted scheduler task)
            locked_job = Delayed::Job.last
            locked_job.update!(locked_at: Time.zone.now)

            expect do
              simulate_threads_call
            end.to not_change {
              Delayed::Job.count
            }.and change {
              Delayed::Job.last.locked_at
            }
          end

          it 'gets destroyed for negative responses' do
            SpecSpace::DelayedJobBackend.reschedule = false
            SpecSpace::DelayedJobBackend.delay.start

            # lock job (simluates interrupted scheduler task)
            locked_job = Delayed::Job.last
            locked_job.update!(locked_at: Time.zone.now)

            expect do
              simulate_threads_call
            end.to change {
              Delayed::Job.count
            }.by(-1)
          end
        end
      end
    end

    context 'ImportJob' do

      context 'affected job' do

        let(:job) { create(:import_job, started_at: 5.minutes.ago) }

        it 'finishes stuck jobs' do

          expect do
            simulate_threads_call
          end.to change {
            job.reload.finished_at
          }
        end

        it 'adds an error message to the result' do

          expect do
            simulate_threads_call
          end.to change {
            job.reload.result[:error]
          }
        end
      end

      it "doesn't change jobs added after stop" do

        job = create(:import_job)

        expect do
          simulate_threads_call
        end.not_to change {
          job.reload
        }
      end
    end
  end
end
