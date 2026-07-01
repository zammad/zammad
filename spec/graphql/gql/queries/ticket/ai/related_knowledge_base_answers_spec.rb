# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Queries::Ticket::AI::RelatedKnowledgeBaseAnswers, authenticated_as: :agent, type: :graphql do
  let(:agent)          { create(:agent, groups: [ticket.group]) }
  let(:ticket)         { create(:ticket) }
  let(:answer)         { create(:knowledge_base_answer, :published) }
  let(:translation)    { answer.translations.first }
  let(:service_result) { { answers: [{ translation:, score: 0.9 }], pending: false } }
  let(:variables)      { { ticketId: gql.id(ticket) } }
  let(:query) do
    <<~QUERY
      query ticketAIRelatedKnowledgeBaseAnswers($ticketId: ID!) {
        ticketAIRelatedKnowledgeBaseAnswers(ticketId: $ticketId) {
          pending
          answers {
            score
            translation {
              title
            }
          }
        }
      }
    QUERY
  end

  before do
    setup_ai_provider('zammad_ai')

    allow(Service::AI::VectorDB::Available).to receive(:execute).and_return(true)
    # The knowledge base answer factory triggers the vector index callback, which must not reach
    # Elasticsearch in this spec.
    allow(Service::AI::VectorDB::Available).to receive(:execute).with(ping: false).and_return(false)
    allow(Service::Ticket::AI::RelatedKnowledgeBaseAnswers).to receive(:execute).and_return(service_result)

    gql.execute(query, variables:)
  end

  context 'when the search returns results' do
    it 'returns the answers with their score' do
      expect(gql.result.data).to eq(
        'pending' => false,
        'answers' => [{ 'score' => 0.9, 'translation' => { 'title' => translation.title } }],
      )
    end
  end

  context 'when the ticket summary is not generated yet' do
    let(:service_result) { { answers: nil, pending: true } }

    it 'reports the summary as pending with no answers' do
      expect(gql.result.data).to eq(
        'pending' => true,
        'answers' => nil,
      )
    end
  end

  context 'when the vector database is unavailable' do
    before do
      allow(Service::AI::VectorDB::Available).to receive(:execute).and_return(false)
      gql.execute(query, variables:)
    end

    it 'returns an error' do
      expect(gql.result.error_message).to eq('Knowledge base vector search is not available.')
    end
  end

  context 'when the agent lacks knowledge base permission' do
    let(:agent) { create(:agent, roles: [create(:role, permission_names: %w[ticket.agent])], groups: [ticket.group]) }

    it 'is forbidden' do
      expect(gql.result.error_type).to eq(Exceptions::Forbidden)
    end
  end
end
