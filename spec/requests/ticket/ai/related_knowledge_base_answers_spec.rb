# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Ticket AI Related Knowledge Base Answers API endpoint', :aggregate_failures, authenticated_as: :agent, type: :request do
  let(:group)              { create(:group) }
  let(:agent)              { create(:agent, groups: [group]) }
  let(:ticket)             { create(:ticket, group:) }
  let(:vectordb_available) { true }
  let(:answer)             { create(:knowledge_base_answer, :published) }
  let(:translation)        { answer.translations.first }
  let(:service_result)     { { answers: [{ translation:, score: 0.9 }], pending: false } }
  let(:params)             { {} }

  before do
    setup_ai_provider('zammad_ai')

    allow(Service::AI::VectorDB::Available).to receive(:execute).and_return(vectordb_available)
    # The knowledge base answer factory triggers the vector index callback, which must not reach
    # Elasticsearch in this spec.
    allow(Service::AI::VectorDB::Available).to receive(:execute).with(ping: false).and_return(false)
    allow(Service::Ticket::AI::RelatedKnowledgeBaseAnswers).to receive(:execute).and_return(service_result)

    post "/api/v1/tickets/#{ticket.id}/related_knowledge_base_answers", params:, as: :json
  end

  context 'when the search returns results' do
    it 'returns the answers (ids + scores + excerpts) and assets' do
      expect(response).to have_http_status(:ok)
      expect(json_response['result']).to eq(
        'pending'                => false,
        'answer_translation_ids' => [translation.id],
        'scores'                 => { translation.id.to_s => 0.9 },
        'excerpts'               => { translation.id.to_s => translation.content.body_excerpt },
      )
      expect(json_response['assets']).to be_present
    end

    it 'searches only the internally visible answers that are not linked yet' do
      expect(Service::Ticket::AI::RelatedKnowledgeBaseAnswers)
        .to have_received(:execute).with(ticket:, embedding_source: nil, include_drafts_and_archived: false, include_linked_answers: false, current_user: agent)
    end
  end

  context 'when drafts and archived answers are requested' do
    let(:params) { { include_drafts_and_archived: true } }

    it 'hands the flag to the service' do
      expect(Service::Ticket::AI::RelatedKnowledgeBaseAnswers)
        .to have_received(:execute).with(ticket:, embedding_source: nil, include_drafts_and_archived: true, include_linked_answers: false, current_user: agent)
    end
  end

  context 'when the linked answers are requested' do
    let(:params) { { include_linked_answers: true } }

    it 'hands the flag to the service' do
      expect(Service::Ticket::AI::RelatedKnowledgeBaseAnswers)
        .to have_received(:execute).with(ticket:, embedding_source: nil, include_drafts_and_archived: false, include_linked_answers: true, current_user: agent)
    end
  end

  context 'when the ticket summary is not generated yet' do
    let(:service_result) { { answers: nil, pending: true } }

    it 'reports the summary as pending' do
      expect(response).to have_http_status(:ok)
      expect(json_response).to eq('result' => { 'pending' => true })
    end
  end

  context 'when the vector database is unavailable' do
    let(:vectordb_available) { false }

    it 'returns an error' do
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  context 'when the agent has no access to the ticket' do
    let(:ticket) { create(:ticket) }

    it 'returns forbidden' do
      expect(response).to have_http_status(:forbidden)
    end
  end

  # Which answers may be suggested is up to the search (published answers only for them), so the
  # endpoint itself stays available.
  context 'when the agent lacks knowledge base permission' do
    let(:agent) { create(:agent, roles: [create(:role, permission_names: %w[ticket.agent])], groups: [group]) }

    it 'returns the answers' do
      expect(response).to have_http_status(:ok)
      expect(json_response['result']['answer_translation_ids']).to eq([translation.id])
    end
  end
end
