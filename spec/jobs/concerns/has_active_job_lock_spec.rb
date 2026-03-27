# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# ActiveJobLock is a job concern, but it heavily relies on Delayed::Job
# If type is set to job, RSpec uses special ActiveJob test adapter
# Thus different type has to be set
RSpec.describe HasActiveJobLock, type: :model do

  before do
    stub_const job_class_namespace, job_class
  end

  let(:job_class_namespace) { 'UniqueActiveJob' }

  let(:job_class) do
    Class.new(ApplicationJob) do
      include HasActiveJobLock

      cattr_accessor :perform_counter, default: 0

      def perform(...)
        self.class.perform_counter += 1
      end
    end
  end

  shared_examples 'handle locking of jobs' do |behaviour: :dismiss|
    context 'performing job is present' do

      before do
        job_class.perform_later
        # simulate a lock with a job-in-progress
        ActiveJobLock.last.update!(created_at: 1.minute.ago, updated_at: 1.second.ago)
      end

      case behaviour
      when :dismiss_running
        it 'does not allow enqueueing of perform_later jobs' do
          expect { job_class.perform_later }.not_to change(Delayed::Job, :count)
        end
      else
        it 'allows enqueueing of perform_later jobs' do
          expect { job_class.perform_later }.to change(Delayed::Job, :count).by(1)
        end
      end

      it 'allows execution of perform_now jobs' do
        expect { job_class.perform_now }.to change(job_class, :perform_counter).by(1)
      end

      context 'with a date' do
        case behaviour
        when :dismiss_running
          it 'does not allow enqueueing of perform_later jobs' do
            expect { job_class.set(wait: 1.minute).perform_later }
              .not_to change(Delayed::Job, :count)
          end
        else
          it 'allows enqueueing of perform_later jobs' do
            expect { job_class.set(wait: 1.minute).perform_later }
              .to change(Delayed::Job, :count).by(1)
          end
        end
      end
    end

    context 'enqueued job is present' do

      before { job_class.perform_later }

      it 'does not enqueue perform_later jobs' do
        expect { job_class.perform_later }.not_to change(Delayed::Job, :count)
      end

      it 'allows execution of perform_now jobs' do
        expect { job_class.perform_now }.to change(job_class, :perform_counter).by(1)
      end

      context 'with a date' do
        let(:related_delayed_job) { Delayed::Job.where("handler LIKE '%job_class: UniqueActiveJob%'").last }

        it 'does not enqueue a new job' do
          expect { job_class.set(wait_until: 1.year.from_now).perform_later }
            .not_to change(Delayed::Job, :count)
        end

        case behaviour
        when :upsert_date
          it 'bumps original job perform date' do
            target_time = 1.day.from_now.beginning_of_minute

            expect { job_class.set(wait_until: target_time).perform_later }
              .to change { related_delayed_job.reload.run_at }
              .to target_time
          end
        else
          it 'does not allow enqueing of perform_later jobs' do
            expect { job_class.set(wait: 1.minute).perform_later }
              .not_to change { related_delayed_job.reload.run_at }
          end
        end
      end
    end

    context 'running perform_now job' do

      let(:job_class) do
        Class.new(super()) do

          cattr_accessor :task_completed, default: false

          def perform(long_running: false)

            if long_running
              sleep(0.1) until self.class.task_completed
            end

            # don't pass parameters to super method
            super()
          end
        end
      end

      let!(:thread) { Thread.new { job_class.perform_now(long_running: true) } }

      after do
        job_class.task_completed = true
        thread.join
      end

      it 'enqueues perform_later jobs' do
        expect { job_class.perform_later }.to change(Delayed::Job, :count).by(1)
      end

      it 'allows execution of perform_now jobs' do
        expect { job_class.perform_now }.to change(job_class, :perform_counter).by(1)
      end

      context 'when Delayed::Job gets destroyed' do

        before do
          ActiveJob::Base.queue_adapter = :delayed_job
        end

        it 'is ensured that ActiveJobLock gets removed' do
          job = job_class.perform_later

          expect do
            Delayed::Job.find(job.provider_job_id).destroy!
          end.to change {
            ActiveJobLock.exists?(lock_key: job.lock_key, active_job_id: job.job_id)
          }.to(false)
        end
      end
    end

    context 'dynamic lock key' do

      let(:job_class) do
        Class.new(super()) do

          def lock_key
            "#{super}/#{arguments[0]}/#{arguments[1]}"
          end
        end
      end

      it 'queues one job per lock key' do
        expect do
          2.times { job_class.perform_later('User', 23) }
          job_class.perform_later('User', 42)
        end.to change(Delayed::Job, :count).by(2)
      end
    end

    context "when ActiveRecord::SerializationFailure 'PG::TRSerializationFailure: ERROR: could not serialize access due to concurrent update' is raised" do

      it 'retries execution until succeed' do
        allow(ActiveRecord::Base.connection).to receive(:open_transactions).and_return(0)
        allow(ActiveJobLock).to receive(:transaction).and_call_original
        exception_raised = false
        allow(ActiveJobLock).to receive(:transaction).with(isolation: :serializable) do |&block|

          if !exception_raised
            exception_raised = true
            raise ActiveRecord::SerializationFailure, 'PG::TRSerializationFailure: ERROR:  could not serialize access due to concurrent update'
          end

          block.call
        end

        expect { job_class.perform_later }.to change(Delayed::Job, :count).by(1)
        expect(exception_raised).to be true
      end
    end

    context "when ActiveRecord::Deadlocked 'Mysql2::Error: Deadlock found when trying to get lock; try restarting transaction' is raised" do

      it 'retries execution until succeed' do
        allow(ActiveRecord::Base.connection).to receive(:open_transactions).and_return(0)
        allow(ActiveJobLock).to receive(:transaction).and_call_original
        exception_raised = false
        allow(ActiveJobLock).to receive(:transaction).with(isolation: :serializable) do |&block|

          if !exception_raised
            exception_raised = true
            raise ActiveRecord::Deadlocked, 'Mysql2::Error: Deadlock found when trying to get lock; try restarting transaction'
          end

          block.call
        end

        expect { job_class.perform_later }.to change(Delayed::Job, :count).by(1)
        expect(exception_raised).to be true
      end
    end
  end

  include_examples 'handle locking of jobs'

  context 'when has custom lock key' do

    let(:job_class) do
      Class.new(super()) do

        def lock_key
          'custom_lock_key'
        end
      end
    end

    include_examples 'handle locking of jobs', behaviour: :dismiss
  end

  context 'when has upsert date lock behaviour' do
    before do
      stub_const "#{job_class.name}::EXISTING_ACTIVE_JOB_LOCK_BEHAVIOUR", :upsert_date
    end

    include_examples 'handle locking of jobs', behaviour: :upsert_date
  end

  context 'when has dismiss including when running lock behaviour' do
    before do
      stub_const "#{job_class.name}::EXISTING_ACTIVE_JOB_LOCK_BEHAVIOUR", :dismiss_running
    end

    include_examples 'handle locking of jobs', behaviour: :dismiss_running
  end

  context 'when has invalid custom lock key' do

    let(:job_class) do
      Class.new(super()) do

        def lock_key
          raise 'Cannot generate lock key anymore'
        end
      end
    end

    it 'does not allow enqueueing of perform_later jobs' do
      expect { job_class.perform_later }.not_to change(Delayed::Job, :count)
    end

    it 'does not allow execution of perform_now jobs' do
      expect { job_class.perform_now }.not_to change(job_class, :perform_counter)
    end
  end

  # https://github.com/zammad/zammad/issues/4141
  context 'when key becomes invalid after enqueueing' do
    let(:job_class) do
      Class.new(super()) do
        cattr_accessor :allow_lock_key, default: true

        def lock_key
          raise 'Cannot generate lock key anymore' if !allow_lock_key

          'lock key'
        end
      end
    end

    it 'safely handles error in generating lock key', performs_jobs: true do
      job_class.perform_later

      job_class.allow_lock_key = false

      expect { perform_enqueued_jobs(only: job_class) }
        .not_to raise_error
    end
  end

  context 'when lock is present, but job is missing' do
    before do
      create(:active_job_lock, lock_key: job_class.name)
    end

    context 'when EXISTING_ACTIVE_JOB_LOCK_BEHAVIOUR is set to :dismiss_running' do
      before do
        stub_const "#{job_class.name}::EXISTING_ACTIVE_JOB_LOCK_BEHAVIOUR", :dismiss_running
      end

      it 'allows enqueueing of a job' do
        expect { job_class.perform_later }.to change(Delayed::Job, :count).by(1)
      end
    end

    context 'when EXISTING_ACTIVE_JOB_LOCK_BEHAVIOUR is set to :dismiss' do
      before do
        stub_const "#{job_class.name}::EXISTING_ACTIVE_JOB_LOCK_BEHAVIOUR", :dismiss
      end

      it 'allows enqueueing of a job' do
        expect { job_class.perform_later }.to change(Delayed::Job, :count).by(1)
      end
    end
  end
end
