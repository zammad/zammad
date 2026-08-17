# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe VectorIndexRebuildJob, :aggregate_failures, type: :job do
  subject(:perform_job) { job.perform_now }

  # `executions` is what the job counts its attempts by, and what perform_now increments on the way
  # in - so a job constructed with the previous count stands in for a run that already failed.
  let(:job)               { described_class.new.tap { |instance| instance.executions = previous_attempts } }
  let(:previous_attempts) { 0 }

  let(:connection) do
    create(:ai_provider_connection, :default_embedding, provider: 'open_ai',
                                                        config:   { token: 'secret-token', embedding_model: 'text-embedding-3-small' })
  end

  before do
    connection
    Setting.set('ai_provider', true)
    Setting.set('vectordb_enabled', true)

    allow(Service::Ticket::AI::RelatedKnowledgeBaseAnswers::EmbeddingCache).to receive(:purge)
    allow(Service::AI::VectorDB::Embedding::Cache).to receive(:purge)
    allow(Service::AI::VectorDB::Rebuild).to receive(:execute)
    allow(Service::AI::VectorDB::Reload).to receive(:execute)
    allow(Service::AI::VectorDB::Available).to receive(:execute).and_return(true)
    # Truthy, because that is what a retry that actually got enqueued returns - the job treats a
    # falsey answer as a dismissed enqueue and fails instead of retrying.
    allow(job).to receive(:retry_job).and_return(true)

    # Switching the settings on above reconciles as well - cleared, so no example inherits its
    # enqueue or the lock that would have the next one dismissed.
    clear_jobs
  end

  context 'when the index has never been built' do
    it 'rebuilds rather than reloads' do
      perform_job

      expect(Service::AI::VectorDB::Rebuild).to have_received(:execute)
      expect(Service::AI::VectorDB::Reload).not_to have_received(:execute)
    end

    # Their key separates no model from another, so a rebuild that left them would have the search
    # comparing two embedding spaces - and they are refilled a ticket at a time on demand.
    it 'purges the ticket embeddings before rebuilding', :aggregate_failures do
      perform_job

      expect(Service::Ticket::AI::RelatedKnowledgeBaseAnswers::EmbeddingCache).to have_received(:purge).ordered
      expect(Service::AI::VectorDB::Rebuild).to have_received(:execute).ordered
    end

    # Nothing recorded what produced them, and their model-scoped digests make leftovers of another
    # model unreadable rather than wrong - so any of the current model are reused, not paid for again.
    it 'keeps the knowledge base vectors' do
      perform_job

      expect(Service::AI::VectorDB::Embedding::Cache).not_to have_received(:purge)
    end

    it 'records the configuration the index was just built with' do
      perform_job

      expect(Service::AI::VectorDB::Embedding::Configuration.indexed)
        .to eq(model: 'text-embedding-3-small', size: AI::Provider::EMBEDDING_SIZES['text-embedding-3-small'])
    end
  end

  context 'when the index already matches the current configuration' do
    before { Service::AI::VectorDB::Embedding::Configuration.record_indexed(Service::AI::VectorDB::Embedding::Configuration.current) }

    it 'reloads rather than rebuilds' do
      perform_job

      expect(Service::AI::VectorDB::Reload).to have_received(:execute)
      expect(Service::AI::VectorDB::Rebuild).not_to have_received(:execute)
    end

    it 'purges neither cache' do
      perform_job

      expect(Service::Ticket::AI::RelatedKnowledgeBaseAnswers::EmbeddingCache).not_to have_received(:purge)
      expect(Service::AI::VectorDB::Embedding::Cache).not_to have_received(:purge)
    end

    # The toggle path: the feature was switched off and on again, so nothing changed about the
    # configuration, but the index itself is gone and has to be rebuilt from scratch.
    context 'when the index itself is missing' do
      before { allow(Service::AI::VectorDB::Available).to receive(:execute).and_return(false) }

      it 'rebuilds' do
        perform_job

        expect(Service::AI::VectorDB::Rebuild).to have_received(:execute)
      end

      # The caches already hold vectors of the very configuration this rebuilds with again.
      it 'purges neither cache' do
        perform_job

        expect(Service::Ticket::AI::RelatedKnowledgeBaseAnswers::EmbeddingCache).not_to have_received(:purge)
        expect(Service::AI::VectorDB::Embedding::Cache).not_to have_received(:purge)
      end
    end
  end

  context 'when the configuration changed since the index was built' do
    before { Service::AI::VectorDB::Embedding::Configuration.record_indexed({ model: 'text-embedding-3-large', size: 3072 }) }

    it 'rebuilds' do
      perform_job

      expect(Service::AI::VectorDB::Rebuild).to have_received(:execute)
    end

    it 'purges both caches, the vectors of a configuration the index no longer holds', :aggregate_failures do
      perform_job

      expect(Service::Ticket::AI::RelatedKnowledgeBaseAnswers::EmbeddingCache).to have_received(:purge)
      expect(Service::AI::VectorDB::Embedding::Cache).to have_received(:purge)
    end

    it 'records the new configuration once the rebuild is done' do
      perform_job

      expect(Service::AI::VectorDB::Embedding::Configuration.indexed)
        .to eq(model: 'text-embedding-3-small', size: AI::Provider::EMBEDDING_SIZES['text-embedding-3-small'])
    end

    # What the attempt before it cached is what makes the next one cheap.
    context 'when a previous attempt already ran' do
      let(:previous_attempts) { 1 }

      it 'does not purge again', :aggregate_failures do
        perform_job

        expect(Service::Ticket::AI::RelatedKnowledgeBaseAnswers::EmbeddingCache).not_to have_received(:purge)
        expect(Service::AI::VectorDB::Embedding::Cache).not_to have_received(:purge)
        expect(Service::AI::VectorDB::Rebuild).to have_received(:execute)
      end
    end
  end

  # From the drop until the rebuild has finished, nothing can be said about what the index holds -
  # so nothing is claimed. Every unhappy ending leaves "nothing built", and the next reconcile
  # rebuilds instead of mistaking a revert for "nothing to do".
  describe 'the record of what the index holds' do
    before do
      Service::AI::VectorDB::Embedding::Configuration.record_indexed({ model: 'text-embedding-3-large', size: 3072 })
    end

    it 'is cleared before the index is dropped' do
      allow(Service::AI::VectorDB::Rebuild).to receive(:execute) do
        expect(Service::AI::VectorDB::Embedding::Configuration.indexed).to be_nil
      end

      perform_job
    end

    context 'when the run stops because it became obsolete' do
      before { allow(Service::AI::VectorDB::Rebuild).to receive(:execute).and_raise(Service::AI::VectorDB::Reload::Aborted) }

      it 'stays cleared, and no attempt is spent on it', :aggregate_failures do
        perform_job

        expect(Service::AI::VectorDB::Embedding::Configuration.indexed).to be_nil
        expect(job).not_to have_received(:retry_job)
      end
    end

    # The retry continues this run, so the record stays cleared for it too.
    context 'when the run fails' do
      before { allow(Service::AI::VectorDB::Rebuild).to receive(:execute).and_raise(AI::Provider::ResponseError, 'nope') }

      it 'stays cleared', :aggregate_failures do
        perform_job

        expect(Service::AI::VectorDB::Embedding::Configuration.indexed).to be_nil
        expect(job).to have_received(:retry_job)
      end
    end

    # Nothing to correct afterwards otherwise: the index is empty or half-filled, and the admin
    # reverting to the model it used to hold would compare as "nothing to do".
    context 'when the run fails for good' do
      let(:previous_attempts) { described_class::ATTEMPTS }

      before { allow(Service::AI::VectorDB::Rebuild).to receive(:execute).and_raise(AI::Provider::ResponseError, 'nope') }

      it 'stays cleared' do
        expect { perform_job }.to raise_error(AI::Provider::ResponseError)

        expect(Service::AI::VectorDB::Embedding::Configuration.indexed).to be_nil
      end
    end

    # Nothing was dropped there, so the record was true all along and stays.
    context 'when a reload stops instead of a rebuild' do
      before do
        Service::AI::VectorDB::Embedding::Configuration.record_indexed(Service::AI::VectorDB::Embedding::Configuration.current)

        allow(Service::AI::VectorDB::Reload).to receive(:execute).and_raise(Service::AI::VectorDB::Reload::Aborted)
      end

      it 'keeps the record of the intact index', :aggregate_failures do
        perform_job

        expect(Service::AI::VectorDB::Embedding::Configuration.indexed)
          .to eq(model: 'text-embedding-3-small', size: AI::Provider::EMBEDDING_SIZES['text-embedding-3-small'])
        expect(job).not_to have_received(:retry_job)
      end
    end
  end

  # One rebuild at a time, even while one is running: with several ai worker threads, an enqueue
  # merely queued behind a running rebuild would start alongside it and drop the index out from
  # under it - so it is dismissed instead, and the running job restarts itself once done if the
  # state still calls for it.
  describe 'one rebuild at a time', performs_jobs: true do
    context 'with a rebuild being performed right now' do
      before do
        described_class.perform_later
        # A started lock is what tells a running job from a waiting one - the old :dismiss
        # behaviour let an enqueue pass it, which is exactly the drop-under-a-runner this pins.
        ActiveJobLock.find_by(lock_key: described_class.name).touch
      end

      it 'dismisses a further enqueue' do
        expect { described_class.perform_later }.not_to have_enqueued_job(described_class)
      end
    end

    context 'with a rebuild waiting in the queue' do
      before { described_class.perform_later }

      it 'dismisses a further enqueue' do
        expect { described_class.perform_later }.not_to have_enqueued_job(described_class)
      end
    end

    # What a dismissed enqueue asked for is never lost: after the lock is released, the state is
    # compared once more - a change up to that point is found here, a later one enqueues freely.
    context 'when the configuration moved while the job was running' do
      before do
        Service::AI::VectorDB::Embedding::Configuration.record_indexed(Service::AI::VectorDB::Embedding::Configuration.current)

        # update_column: no callbacks, so the restart can only come from the job itself.
        allow(Service::AI::VectorDB::Reload).to receive(:execute) do
          connection.update_column(:config, connection.config.merge('embedding_model' => 'text-embedding-3-large'))
        end
      end

      it 'restarts itself once done' do
        expect { perform_job }.to have_enqueued_job(described_class)
      end
    end

    context 'when the run ends with the state it recorded' do
      before { Service::AI::VectorDB::Embedding::Configuration.record_indexed(Service::AI::VectorDB::Embedding::Configuration.current) }

      it 'does not restart itself' do
        expect { perform_job }.not_to have_enqueued_job(described_class)
      end
    end

    # A restart on top of a failed run would rebuild alongside its pending retry.
    context 'when the run failed and will be retried' do
      before do
        allow(Service::AI::VectorDB::Rebuild).to receive(:execute).and_raise(AI::Provider::ResponseError, 'nope')
      end

      it 'does not restart itself' do
        expect { perform_job }.not_to have_enqueued_job(described_class)
      end
    end

    context 'when the run gave up for good' do
      let(:previous_attempts) { described_class::ATTEMPTS }

      before do
        allow(Service::AI::VectorDB::Rebuild).to receive(:execute).and_raise(AI::Provider::ResponseError, 'nope')
      end

      # Restarting here would loop a permanently failing rebuild forever; recovery is whatever
      # reconcile trigger comes next, with the failed job on record for the health check.
      it 'does not restart itself' do
        expect do
          expect { perform_job }.to raise_error(AI::Provider::ResponseError)
        end.not_to have_enqueued_job(described_class)
      end
    end
  end

  # retry_job enqueues a dup carrying this job's id, so the retry takes the lock over - and releasing
  # it afterwards would leave the pending retry unguarded, with a second rebuild free to drop and
  # refill the index alongside it.
  describe 'the lock a retry inherits' do
    subject(:lock) { ActiveJobLock.where(lock_key: job.lock_key) }

    before do
      ActiveJobLock.create!(lock_key: job.lock_key, active_job_id: job.job_id)
    end

    context 'when the rebuild failed and a retry is pending' do
      before do
        allow(Service::AI::VectorDB::Rebuild).to receive(:execute).and_raise(AI::Provider::ResponseError, 'nope')

        # The real enqueue, because the lock the retry ends up holding is the one its own enqueue
        # creates - a stubbed retry would leave nothing to observe.
        allow(job).to receive(:retry_job).and_call_original
      end

      it 'is held by the retry rather than released with this run' do
        perform_job

        expect(lock).to exist
      end

      # :dismiss_running throws away an enqueue that finds a lock whose job still exists - and under
      # the production adapter this job's own row is exactly that while it performs. Its retry would
      # be dismissed, this run would return as if it had succeeded, and a half-built index would be
      # left with no retry and no failed job anywhere to report it.
      context 'with its own job still on record, as the production adapter leaves it' do
        before do
          queue_adapter.enqueued_jobs << { 'job_id' => job.job_id, job: described_class, args: [], queue: 'ai' }
        end

        it 'enqueues the retry all the same', :aggregate_failures do
          expect { perform_job }.to have_enqueued_job(described_class)
          expect(lock).to exist
        end
      end
    end

    context 'when the rebuild finished' do
      it 'is released' do
        perform_job

        expect(lock).not_to exist
      end
    end
  end

  context 'when the vector database was disabled before the job runs' do
    before do
      Setting.set('vectordb_enabled', false)
    end

    it 'leaves the index alone', :aggregate_failures do
      perform_job

      expect(Service::AI::VectorDB::Rebuild).not_to have_received(:execute)
      expect(Service::AI::VectorDB::Reload).not_to have_received(:execute)
    end
  end

  context 'when nothing serves embeddings' do
    before do
      Service::AI::VectorDB::Embedding::Configuration.record_indexed({ model: 'text-embedding-3-small', size: 1536 })
      connection.update!(default_embedding: false)
    end

    it 'leaves the index alone', :aggregate_failures do
      perform_job

      expect(Service::AI::VectorDB::Rebuild).not_to have_received(:execute)
      expect(Service::AI::VectorDB::Reload).not_to have_received(:execute)
    end

    it 'does not overwrite what the index was recorded to hold' do
      expect { perform_job }.not_to change(Service::AI::VectorDB::Embedding::Configuration, :indexed)
    end
  end

  # A configuration changed while this very attempt was running: the run itself only ever judges and
  # records against the value it captured at the start, so it is the self-check at the end that
  # notices and repairs it - by enqueuing its own successor.
  describe 'self-check after the run' do
    it 'enqueues its own successor when the configuration changed mid-run' do
      allow(Service::AI::VectorDB::Rebuild).to receive(:execute) do
        connection.update_column(:config, connection.config.merge('embedding_model' => 'text-embedding-3-large'))
      end

      expect { perform_job }.to have_enqueued_job(described_class)
    end

    it 'does not enqueue a successor when nothing changed during the run' do
      expect { perform_job }.not_to have_enqueued_job(described_class)
    end
  end

  # One curve for every kind of failure: the providers signal a rate limit in whatever way they
  # please, so none of them is treated as a case of its own.
  context 'when the rebuild fails' do
    let(:error) { AI::Provider::ResponseError.new('Rate limit exceeded - please wait a moment') }

    before do
      allow(Service::AI::VectorDB::Rebuild).to receive(:execute).and_raise(error)
    end

    it 'starts with a short wait, where a blipping endpoint is the likely cause' do
      perform_job

      expect(job).to have_received(:retry_job).with(wait: 30.seconds, error:)
    end

    context 'when several attempts have already failed' do
      let(:previous_attempts) { 4 }

      it 'waits longer, where a provider quota is' do
        perform_job

        expect(job).to have_received(:retry_job).with(wait: 8.minutes, error:)
      end
    end

    context 'when the attempts have gone on long enough' do
      let(:previous_attempts) { 8 }

      it 'stops growing the wait at half an hour' do
        perform_job

        expect(job).to have_received(:retry_job).with(wait: 30.minutes, error:)
      end
    end

    context 'when the retry budget is exhausted' do
      let(:previous_attempts) { described_class::ATTEMPTS }

      it 'gives up and lets the job fail' do
        expect { perform_job }.to raise_error(error)
      end
    end
  end
end
