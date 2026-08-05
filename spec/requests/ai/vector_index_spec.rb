# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'AI vector index', :aggregate_failures, authenticated_as: :user, type: :request do
  let(:user) do
    create(:agent, roles: [create(:role, permission_names: %w[admin.ai_knowledge_base admin.ai_provider])])
  end

  before do
    allow(VectorIndexSyncJob).to receive(:perform_later)
    allow(Service::AI::VectorDB::CreateTable).to receive(:execute)
    allow(Service::AI::VectorDB::Reload).to receive(:execute)

    post '/api/v1/ai/vector_index/sync', as: :json
  end

  it 'schedules the vector index sync without performing it in the request' do
    expect(response).to have_http_status(:ok)
    expect(json_response).to eq('success' => true)
    expect(VectorIndexSyncJob).to have_received(:perform_later).once
    expect(Service::AI::VectorDB::CreateTable).not_to have_received(:execute)
    expect(Service::AI::VectorDB::Reload).not_to have_received(:execute)
  end

  shared_examples 'allowed to sync the vector index' do
    it 'schedules the vector index sync' do
      expect(response).to have_http_status(:ok)
      expect(VectorIndexSyncJob).to have_received(:perform_later).once
    end
  end

  context 'with only the knowledge base AI administration permission' do
    let(:user) { create(:agent, roles: [create(:role, permission_names: %w[admin.ai_knowledge_base])]) }

    include_examples 'allowed to sync the vector index'
  end

  context 'with only the provider AI administration permission' do
    let(:user) { create(:agent, roles: [create(:role, permission_names: %w[admin.ai_provider])]) }

    include_examples 'allowed to sync the vector index'
  end

  context 'without either AI administration permission' do
    let(:user) { create(:agent) }

    it 'returns forbidden without changing the index' do
      expect(response).to have_http_status(:forbidden)
      expect(VectorIndexSyncJob).not_to have_received(:perform_later)
      expect(Service::AI::VectorDB::CreateTable).not_to have_received(:execute)
      expect(Service::AI::VectorDB::Reload).not_to have_received(:execute)
    end
  end
end
