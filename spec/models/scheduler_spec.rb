require 'rails_helper'

RSpec.describe Scheduler do

  before do
    module SpecSpace
      class DelayedJobBackend

        def self.start
          # noop
        end

        # rubocop:disable Style/TrivialAccessors
        def self.reschedule=(reschedule)
          @reschedule = reschedule
        end

        def self.reschedule?(_delayed_job)
          @reschedule || false
        end
      end
    end
  end

  after do
    SpecSpace.send(:remove_const, :DelayedJobBackend)
  end

  describe '.cleanup' do

    it 'gets called by .threads' do
      expect(described_class).to receive(:cleanup).and_throw(:called)
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

    it 'keeps unlocked Delayed::Job-s' do
      # meta :)
      described_class.delay.cleanup

      expect do
        simulate_threads_call
      end.not_to change {
        Delayed::Job.count
      }
    end

    context 'locked Delayed::Job' do

      it 'gets destroyed' do
        # meta :)
        described_class.delay.cleanup

        # lock job (simluates interrupted scheduler task)
        locked_job = Delayed::Job.last
        locked_job.update_attribute(:locked_at, Time.zone.now)

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
          locked_job.update_attribute(:locked_at, Time.zone.now)

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
          locked_job.update_attribute(:locked_at, Time.zone.now)

          expect do
            simulate_threads_call
          end.to change {
            Delayed::Job.count
          }.by(-1)
        end
      end
    end
  end
end
