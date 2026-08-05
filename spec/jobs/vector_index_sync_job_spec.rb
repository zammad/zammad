# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe VectorIndexSyncJob, :aggregate_failures, type: :job do
  subject(:perform_job) { described_class.perform_now }

  before do
    setup_ai_provider
    Setting.set('vectordb_enabled', true)

    allow(Service::AI::VectorDB::Available).to receive(:execute).and_return(index_available)
    allow(Service::AI::VectorDB::CreateTable).to receive(:execute)
    allow(Service::AI::VectorDB::Reload).to receive(:execute)
  end

  context 'when the vector index exists' do
    let(:index_available) { true }

    it 'updates the existing index' do
      perform_job

      expect(Service::AI::VectorDB::CreateTable).not_to have_received(:execute)
      expect(Service::AI::VectorDB::Reload).to have_received(:execute).with(fresh: false)
    end
  end

  context 'when the vector index does not exist' do
    let(:index_available) { false }

    it 'creates the index and fully reindexes it' do
      perform_job

      expect(Service::AI::VectorDB::CreateTable).to have_received(:execute).once
      expect(Service::AI::VectorDB::Reload).to have_received(:execute).with(fresh: true)
    end
  end

  context 'when the vector database was disabled before the job runs' do
    let(:index_available) { true }

    before do
      Setting.set('vectordb_enabled', false)
    end

    it 'does not change the index' do
      perform_job

      expect(Service::AI::VectorDB::Available).not_to have_received(:execute)
      expect(Service::AI::VectorDB::CreateTable).not_to have_received(:execute)
      expect(Service::AI::VectorDB::Reload).not_to have_received(:execute)
    end
  end
end
