# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Ticket AI Knowledge Base Answers API endpoint', authenticated_as: :user, performs_jobs: true, type: :request do
  let(:role_editor)                                    { create(:role, permission_names: %w[knowledge_base.editor]) }
  let(:user)                                           { create(:agent).tap { |u| u.roles << role_editor } }
  let(:ticket)                                         { article.ticket }
  let(:article)                                        { create(:ticket_article) }
  let(:ai_assistance_kb_answer_from_ticket_generation) { true }
  let(:params)                                         { {} }

  let(:knowledge_base)          { create(:knowledge_base) }
  let(:knowledge_base_category) { create(:knowledge_base_category, knowledge_base:) }

  before do
    allow(AI::Provider::ZammadAI).to receive(:ping!).and_return(true)

    setup_ai_provider
    Setting.set('ai_assistance_kb_answer_from_ticket_generation', ai_assistance_kb_answer_from_ticket_generation)
  end

  describe '#create' do
    def make_request
      post "/api/v1/tickets/#{ticket.id}/knowledge_base_answers", params:, as: :json
    end

    context 'when feature is disabled' do
      let(:ai_assistance_kb_answer_from_ticket_generation) { false }

      it 'raises error', :aggregate_failures do
        make_request

        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response['error']).to eq('This feature is not enabled.')
      end
    end

    context 'when user does not have agent access' do
      it 'raises error' do
        make_request

        expect(TicketAIAssistanceGenerateKnowledgeBaseAnswerJob).not_to have_been_enqueued
      end
    end

    context 'when user has agent access but no knowledge base editor permission' do
      let(:role_editor) { nil }
      let(:agent_role)  { create(:role, :agent) }
      let(:user)        { create(:user, roles: [agent_role]) }

      before do
        knowledge_base_category
        user.groups << ticket.group
      end

      it 'raises error' do
        make_request

        expect(TicketAIAssistanceGenerateKnowledgeBaseAnswerJob).not_to have_been_enqueued
      end
    end

    context 'when user has agent access' do
      before { user.groups << ticket.group }

      context 'when no knowledge base is available' do
        before do
          allow(KnowledgeBase).to receive(:first).and_return(nil)
        end

        it 'returns an error and does not enqueue job', :aggregate_failures do
          make_request

          expect(response).to have_http_status(:unprocessable_entity)
          expect(json_response).to eq({
                                        'error'         => true,
                                        'error_message' => 'Knowledge base is unavailable or not properly configured.',
                                      })
          expect(TicketAIAssistanceGenerateKnowledgeBaseAnswerJob).not_to have_been_enqueued
        end
      end

      context 'when no knowledge base category is available' do
        before do
          allow(KnowledgeBase).to receive(:first).and_return(knowledge_base)
        end

        it 'returns an error and does not enqueue job', :aggregate_failures do
          make_request

          expect(response).to have_http_status(:unprocessable_entity)
          expect(json_response).to eq({
                                        'error'         => true,
                                        'error_message' => 'Knowledge base is unavailable or not properly configured.',
                                      })
          expect(TicketAIAssistanceGenerateKnowledgeBaseAnswerJob).not_to have_been_enqueued
        end
      end

      context 'when request is valid' do
        before do
          allow(KnowledgeBase).to receive(:first).and_return(knowledge_base)
          knowledge_base_category
        end

        it 'returns empty result and enqueues kb generation job', :aggregate_failures do
          make_request

          expect(response).to have_http_status(:ok)
          expect(json_response).to eq({ 'status' => 'ok' })
          expect(TicketAIAssistanceGenerateKnowledgeBaseAnswerJob).to have_been_enqueued.with(ticket, user, knowledge_base.id)
        end
      end
    end
  end
end
