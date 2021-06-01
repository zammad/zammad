# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe HasActiveJobLock, type: :job do

  before do
    stub_const job_class_namespace, job_class
  end

  let(:job_class_namespace) { 'UniqueActiveJob' }

  let(:job_class) do
    Class.new(ApplicationJob) do
      include HasActiveJobLock

      cattr_accessor :perform_counter, default: 0

      def perform
        self.class.perform_counter += 1
      end
    end
  end

  shared_examples 'handle locking of jobs' do
    context 'performing job is present' do

      before { create(:active_job_lock, lock_key: job_class.name, created_at: 1.minute.ago, updated_at: 1.second.ago) }

      it 'allows enqueueing of perform_later jobs' do
        expect { job_class.perform_later }.to have_enqueued_job(job_class).exactly(:once)
      end

      it 'allows execution of perform_now jobs' do
        expect { job_class.perform_now }.to change(job_class, :perform_counter).by(1)
      end
    end

    context 'enqueued job is present' do

      before { job_class.perform_later }

      it "won't enqueue perform_later jobs" do
        expect { job_class.perform_later }.not_to have_enqueued_job(job_class)
      end

      it 'allows execution of perform_now jobs' do
        expect { job_class.perform_now }.to change(job_class, :perform_counter).by(1)
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
        expect { job_class.perform_later }.to have_enqueued_job(job_class)
      end

      it 'allows execution of perform_now jobs' do
        expect { job_class.perform_now }.to change(job_class, :perform_counter).by(1)
      end

      context 'when Delayed::Job gets destroyed' do

        before do
          ::ActiveJob::Base.queue_adapter = :delayed_job
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
        end.to have_enqueued_job(job_class).exactly(:twice)
      end
    end

    context "when ActiveRecord::SerializationFailure 'PG::TRSerializationFailure: ERROR:  could not serialize access due to concurrent update' is raised" do

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

        expect { job_class.perform_later }.to have_enqueued_job(job_class).exactly(:once)
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

        expect { job_class.perform_later }.to have_enqueued_job(job_class).exactly(:once)
        expect(exception_raised).to be true
      end
    end
  end

  include_examples 'handle locking of jobs'

  context 'custom lock key' do

    let(:job_class) do
      Class.new(super()) do

        def lock_key
          'custom_lock_key'
        end
      end
    end

    include_examples 'handle locking of jobs'
  end
end
