# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::AI::VectorDB::Reconcile, performs_jobs: true do
  subject(:reconcile) { described_class.execute }

  let(:connection) do
    create(:ai_provider_connection, :default_embedding, provider: 'open_ai',
                                                        config:   { token: 'a', embedding_model: 'text-embedding-3-small' })
  end

  before do
    connection
    Setting.set('ai_provider', true)
    Setting.set('vectordb_enabled', true)

    # Both saves reconcile themselves (Setting#schedule_vector_index_reconcile), so what they enqueue
    # is cleared - along with the lock that would have the enqueue under test dismissed onto it.
    clear_jobs
  end

  context 'when the index holds nothing yet' do
    it 'enqueues a rebuild and reports background reconciliation', :aggregate_failures do
      result = nil

      expect { result = reconcile }.to have_enqueued_job(VectorIndexRebuildJob)
      expect(result).to be true
    end

    it 'reports background reconciliation when an existing rebuild coalesces the enqueue' do
      VectorIndexRebuildJob.perform_later

      expect(reconcile).to be true
    end
  end

  context 'when the index matches the current configuration' do
    before { Service::AI::VectorDB::Embedding::Configuration.record_indexed(Service::AI::VectorDB::Embedding::Configuration.current) }

    it 'does nothing', :aggregate_failures do
      result = nil

      expect { result = reconcile }.not_to have_enqueued_job(VectorIndexRebuildJob)
      expect(result).to be_nil
    end
  end

  context 'when the index was built with a different configuration' do
    before { Service::AI::VectorDB::Embedding::Configuration.record_indexed({ model: 'text-embedding-3-large', size: 3072 }) }

    it 'enqueues a rebuild' do
      expect { reconcile }.to have_enqueued_job(VectorIndexRebuildJob)
    end
  end

  context 'when the vector database is switched off' do
    before do
      Setting.set('vectordb_enabled', false)
    end

    it 'does nothing' do
      expect { reconcile }.not_to have_enqueued_job(VectorIndexRebuildJob)
    end
  end

  context 'when nothing serves embeddings' do
    before { connection.update!(default_embedding: false) }

    it 'does nothing, leaving the index standing' do
      expect { reconcile }.not_to have_enqueued_job(VectorIndexRebuildJob)
    end
  end

  context 'when the AI provider is disabled' do
    before { Setting.set('ai_provider', false) }

    it 'does nothing' do
      expect { reconcile }.not_to have_enqueued_job(VectorIndexRebuildJob)
    end
  end
end
