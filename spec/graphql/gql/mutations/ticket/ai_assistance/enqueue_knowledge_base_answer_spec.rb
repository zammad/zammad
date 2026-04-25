# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Mutations::Ticket::AIAssistance::EnqueueKnowledgeBaseAnswer, :aggregate_failures, type: :graphql do
  context 'when generating a knowledge base answer', authenticated_as: :agent, performs_jobs: true do
    let(:role_editor)      { create(:role, permission_names: %w[knowledge_base.editor ticket.agent]) }
    let(:agent)            { create(:agent, roles: [role_editor], groups: [ticket.group]) }
    let(:ticket)           { create(:ticket) }
    let(:knowledge_base)   { create(:knowledge_base) }
    let(:feature_enabled)  { true }
    let(:with_category)    { true }

    let(:query) do
      <<~MUTATION
        mutation ticketAIAssistanceEnqueueKnowledgeBaseAnswer($ticketId: ID!) {
          ticketAIAssistanceEnqueueKnowledgeBaseAnswer(ticketId: $ticketId) {
            success
          }
        }
      MUTATION
    end

    let(:variables) { { ticketId: gql.id(ticket) } }

    before do
      allow(KnowledgeBase).to receive(:first).and_return(knowledge_base)

      create(:knowledge_base_category, knowledge_base:) if with_category && knowledge_base.present?

      setup_ai_provider
      Setting.set('ai_assistance_kb_answer_from_ticket_generation', feature_enabled)

      gql.execute(query, variables:)
    end

    context 'when request is valid' do
      it 'enqueues a background job and returns success' do
        expect(gql.result.data).to include('success' => true)
        expect(TicketAIAssistanceGenerateKnowledgeBaseAnswerJob).to have_been_enqueued
          .with(ticket, agent, knowledge_base.id)
      end
    end

    context 'when feature is disabled' do
      let(:feature_enabled) { false }

      it 'returns an error' do
        expect(gql.result.error_message).to include('This feature is not enabled.')
      end
    end

    context 'when no knowledge base exists' do
      let(:knowledge_base) { nil }

      it 'returns an error' do
        expect(gql.result.error_message).to include('Knowledge base is unavailable or not properly configured.')
      end
    end

    context 'when knowledge base has no categories' do
      let(:with_category) { false }

      it 'returns an error' do
        expect(gql.result.error_message).to include('Knowledge base is unavailable or not properly configured.')
      end
    end

    it_behaves_like 'graphql responds with error if unauthenticated'
  end
end
