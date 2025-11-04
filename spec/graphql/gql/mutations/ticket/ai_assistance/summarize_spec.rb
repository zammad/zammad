# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Mutations::Ticket::AIAssistance::Summarize, :aggregate_failures, type: :graphql do
  context 'when summarizing a ticket', authenticated_as: :agent, performs_jobs: true do
    let(:agent)            { create(:agent, groups: [ticket.group]) }
    let(:ticket)           { create(:ticket) }
    let(:ticket_article)   { create(:ticket_article, ticket: ticket) }
    let(:expected_cache)   { nil }
    let(:ai_analytics_run) { create(:ai_analytics_run, related_object: ticket) }

    let(:query) do
      <<~MUTATION
        mutation ticketAIAssistanceSummarize($ticketId: ID!, $regenerationOfId: ID) {
          ticketAIAssistanceSummarize(ticketId: $ticketId, regenerationOfId: $regenerationOfId) {
            summary {
              customerRequest
              conversationSummary
              openQuestions
              upcomingEvents
              customerMood
              customerEmotion
            }
            analytics {
              run {
                id
              }
              usage {
                userHasProvidedFeedback
              }
              isUnread
            }
          }
        }
      MUTATION
    end

    let(:variables) { { ticketId: gql.id(ticket) } }

    before do
      allow(AI::Provider::ZammadAI).to receive(:ping!).and_return(true)

      Setting.set('ai_assistance_ticket_summary', true)
      setup_ai_provider

      ticket_article

      if expected_cache
        AI::StoredResult.create!(
          content:          expected_cache,
          version:          AI::Service::TicketSummarize.lookup_version({ ticket: }, Locale.find_by(locale: agent.locale)),
          **AI::Service::TicketSummarize.lookup_attributes({ ticket: }, Locale.find_by(locale: agent.locale)),
          ai_analytics_run:
        )
      end

      if defined?(rating)
        create(:ai_analytics_usage, ai_analytics_run: AI::Analytics::Run.last, user: agent, rating:)
      end

      gql.execute(query, variables: variables)
    end

    context 'when the summary is already in the cache' do
      let(:expected_cache) do
        {
          'customer_request'     => 'example',
          'conversation_summary' => 'example',
          'open_questions'       => ['example'],
          'upcoming_events'      => ['example'],
          'customer_mood'        => 'example',
          'customer_emotion'     => 'example',
        }
      end

      it 'returns the cached summary' do
        expect(gql.result.data).to eq(
          'summary'   => {
            'customerRequest'     => 'example',
            'conversationSummary' => 'example',
            'openQuestions'       => ['example'],
            'upcomingEvents'      => ['example'],
            'customerMood'        => 'example',
            'customerEmotion'     => 'example',
          },
          'analytics' => {
            'run'      => {
              'id' => gql.id(AI::Analytics::Run.last),
            },
            'usage'    => nil,
            'isUnread' => true,
          },
        )
      end

      context 'when passing regeneration_of param' do
        let(:variables) { { ticketId: gql.id(ticket), regenerationOfId: gql.id(ai_analytics_run) } }

        it 'enqueues a background job to generate the summary' do
          expect(TicketAIAssistanceSummarizeJob).to have_been_enqueued
            .with(ticket, agent.locale, regeneration_of: ai_analytics_run)
        end
      end

      context 'when user has already added usage' do
        context 'when user added no rating yet' do
          let(:rating) { nil }

          it 'returns cached version with usage info' do
            expect(gql.result.data).to eq(
              'summary'   => {
                'customerRequest'     => 'example',
                'conversationSummary' => 'example',
                'openQuestions'       => ['example'],
                'upcomingEvents'      => ['example'],
                'customerMood'        => 'example',
                'customerEmotion'     => 'example',
              },
              'analytics' => {
                'run'      => {
                  'id' => gql.id(AI::Analytics::Run.last),
                },
                'usage'    => {
                  'userHasProvidedFeedback' => false,
                },
                'isUnread' => false,
              },
            )
          end
        end

        context 'when usage added rating too' do
          let(:rating) { false }

          it 'returns cached version with usage info' do
            expect(gql.result.data).to eq(
              'summary'   => {
                'customerRequest'     => 'example',
                'conversationSummary' => 'example',
                'openQuestions'       => ['example'],
                'upcomingEvents'      => ['example'],
                'customerMood'        => 'example',
                'customerEmotion'     => 'example',
              },
              'analytics' => {
                'run'      => {
                  'id' => gql.id(AI::Analytics::Run.last),
                },
                'usage'    => {
                  'userHasProvidedFeedback' => true,
                },
                'isUnread' => false,
              },
            )
          end
        end
      end
    end

    context 'when the summary is not in the cache' do
      it 'returns nil' do
        expect(gql.result.data).to include(
          summary:   be_nil,
          analytics: be_nil,
        )
      end

      it 'enqueues a background job to generate the summary' do
        expect(TicketAIAssistanceSummarizeJob).to have_been_enqueued
          .with(ticket, agent.locale, regeneration_of: nil)
      end
    end

    it_behaves_like 'graphql responds with error if unauthenticated'
  end
end
