# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Ticket Summarize API endpoints', authenticated_as: :user, performs_jobs: true, type: :request do
  let(:user)                         { create(:agent) }
  let(:ticket)                       { article.ticket }
  let(:article)                      { create(:ticket_article) }
  let(:ai_assistance_ticket_summary) { true }
  let(:params)                       { {} }

  before do
    allow(AI::Provider::ZammadAI).to receive(:ping!).and_return(true)

    setup_ai_provider
    Setting.set('ai_assistance_ticket_summary', ai_assistance_ticket_summary)
  end

  describe '#summarize' do
    def make_request
      post "/api/v1/tickets/#{ticket.id}/summarize", params:, as: :json
    end

    context 'when feature is disabled' do
      let(:ai_assistance_ticket_summary) { false }

      it 'raises error', :aggregate_failures do
        make_request

        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response['error']).to eq('This feature is not enabled.')
      end
    end

    context 'when user does not have agent access' do
      it 'raises error' do
        make_request
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'when user has agent access' do
      before { user.groups << ticket.group }

      context 'when cache is present' do
        let(:result) do
          {
            'customer_request'     => 'mocked customer_request',
            'conversation_summary' => 'mocked conversation_summary',
            'open_questions'       => ['mocked open_questions'],
            'upcoming_events'      => ['mocked upcoming_events'],
            'customer_mood'        => 'mocked customer_mood',
            'customer_emotion'     => 'mocked customer_emotion',
          }
        end

        let(:ai_analytics_run) do
          AI::Analytics::Run.create!(
            content:         result,
            version:         AI::Service::TicketSummarize.lookup_version({ ticket: }, Locale.find_by(locale: user.locale)),
            ai_service_name: 'TicketSummarize',
            **AI::Service::TicketSummarize.lookup_attributes({ ticket: }, Locale.find_by(locale: user.locale)),
          )
        end

        before do
          AI::StoredResult.create!(
            content:          result,
            version:          AI::Service::TicketSummarize.lookup_version({ ticket: }, Locale.find_by(locale: user.locale)),
            **AI::Service::TicketSummarize.lookup_attributes({ ticket: }, Locale.find_by(locale: user.locale)),
            ai_analytics_run:,
          )
        end

        it 'returns cached version' do
          make_request

          expect(json_response).to eq({ 'result'    => {
                                          'customer_request'     => 'mocked customer_request',
                                          'conversation_summary' => 'mocked conversation_summary',
                                          'open_questions'       => ['mocked open_questions'],
                                          'upcoming_events'      => ['mocked upcoming_events'],
                                          'customer_mood'        => 'mocked customer_mood',
                                          'customer_emotion'     => 'mocked customer_emotion',
                                        },
                                        'analytics' => {
                                          'run_id'    => AI::Analytics::Run.last&.id,
                                          'usage'     => nil,
                                          'is_unread' => true,
                                        } })
        end

        context 'when passing regeneration_of param' do
          let(:params) { { regeneration_of_id: ai_analytics_run.id } }

          it 'enqueues summary generation job' do
            make_request

            expect(TicketAIAssistanceSummarizeJob)
              .to have_been_enqueued.with(ticket, user.locale, regeneration_of: ai_analytics_run)
          end

        end

        context 'when user has already added usage' do
          before do
            create(:ai_analytics_usage, ai_analytics_run: AI::Analytics::Run.last, user:, rating:)
          end

          context 'when user added no rating yet' do
            let(:rating) { nil }

            it 'returns cached version with usage info' do
              make_request

              expect(json_response).to eq({ 'result'    => {
                                              'customer_request'     => 'mocked customer_request',
                                              'conversation_summary' => 'mocked conversation_summary',
                                              'open_questions'       => ['mocked open_questions'],
                                              'upcoming_events'      => ['mocked upcoming_events'],
                                              'customer_mood'        => 'mocked customer_mood',
                                              'customer_emotion'     => 'mocked customer_emotion',
                                            },
                                            'analytics' => {
                                              'run_id'    => AI::Analytics::Run.last&.id,
                                              'usage'     => {
                                                'user_has_provided_feedback' => false,
                                              },
                                              'is_unread' => false,
                                            } })
            end
          end

          context 'when usage added rating too' do
            let(:rating) { false }

            it 'returns cached version with usage info' do
              make_request

              expect(json_response).to eq({ 'result'    => {
                                              'customer_request'     => 'mocked customer_request',
                                              'conversation_summary' => 'mocked conversation_summary',
                                              'open_questions'       => ['mocked open_questions'],
                                              'upcoming_events'      => ['mocked upcoming_events'],
                                              'customer_mood'        => 'mocked customer_mood',
                                              'customer_emotion'     => 'mocked customer_emotion',
                                            },
                                            'analytics' => {
                                              'run_id'    => AI::Analytics::Run.last&.id,
                                              'usage'     => {
                                                'user_has_provided_feedback' => true,
                                              },
                                              'is_unread' => false,
                                            } })
            end
          end
        end

        it 'does not enqueue summary generation job' do
          make_request

          expect(TicketAIAssistanceSummarizeJob).not_to have_been_enqueued
        end
      end

      context 'when cache is not present' do
        it 'enqueues summary generation job' do
          make_request

          expect(TicketAIAssistanceSummarizeJob)
            .to have_been_enqueued.with(ticket, user.locale, regeneration_of: nil)
        end

        it 'returns empty result' do
          make_request

          expect(json_response).to eq({ 'result' => nil })
        end
      end
    end
  end
end
