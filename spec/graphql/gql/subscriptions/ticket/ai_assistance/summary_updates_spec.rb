# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Subscriptions::Ticket::AIAssistance::SummaryUpdates, authenticated_as: :agent, type: :graphql do
  let(:agent)            { create(:agent, groups: [ticket.group]) }
  let(:ticket)           { create(:ticket) }
  let(:ai_analytics_run) { create(:ai_analytics_run, related_object: ticket) }
  let(:variables)        { { ticketId: gql.id(ticket), locale: agent.locale } }
  let(:mock_channel)     { build_mock_channel }
  let(:subscription) do
    <<~SUBSCRIPTION
      subscription ticketAIAssistanceSummaryUpdates($ticketId: ID!, $locale: String!) {
        ticketAIAssistanceSummaryUpdates(ticketId: $ticketId, locale: $locale) {
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
          error {
            message
            exception
          }
        }
      }
    SUBSCRIPTION
  end

  before do
    allow(AI::Provider::ZammadAI).to receive(:ping!).and_return(true)

    Setting.set('ai_assistance_ticket_summary', true)
    setup_ai_provider

    gql.execute(subscription, variables: variables, context: { channel: mock_channel })
  end

  context 'when subscribed' do
    it 'subscribes' do
      expect(gql.result.data).to include('summary' => nil)
    end

    context 'when a summary job is executed' do
      let(:expected_summary) do
        {
          'customer_request'     => 'Houston we got a problem',
          'conversation_summary' => 'short summary',
          'open_questions'       => ['question 1', 'question 2'],
          'upcoming_events'      => ['do this and that'],
          'customer_mood'        => 'example',
          'customer_emotion'     => 'example',
        }
      end

      let(:expected_result) do
        AI::Service::Result.new(
          content:          expected_summary,
          fresh:            true,
          ai_analytics_run:
        )
      end

      let(:expected_broadcasted_summary) do
        {
          'customerRequest'     => 'Houston we got a problem',
          'conversationSummary' => 'short summary',
          'openQuestions'       => ['question 1', 'question 2'],
          'upcomingEvents'      => ['do this and that'],
          'customerMood'        => 'example',
          'customerEmotion'     => 'example',
        }
      end

      before do
        allow_any_instance_of(Service::Ticket::AIAssistance::Summarize)
          .to receive(:execute)
          .and_return(expected_result)
      end

      it 'receives new summary data' do
        TicketAIAssistanceSummarizeJob.new.perform(ticket, agent.locale)
        expect(mock_channel.mock_broadcasted_messages.first).to include(
          result: include(
            'data' => include(
              'ticketAIAssistanceSummaryUpdates' => include(
                'summary' => expected_broadcasted_summary,
              )
            )
          )
        )
      end

      context 'when the summary is relevant for the current user' do
        before do
          another_user = create(:agent, groups: [ticket.group])
          create(:ticket_article, :outbound_email, origin_by: another_user, ticket:, body: 'This is a test article')
        end

        it 'receives new summary data' do
          TicketAIAssistanceSummarizeJob.new.perform(ticket, agent.locale)
          expect(mock_channel.mock_broadcasted_messages.first).to include(
            result: include(
              'data' => include(
                'ticketAIAssistanceSummaryUpdates' => include(
                  'summary' => expected_broadcasted_summary,
                )
              )
            )
          )
        end
      end

      context 'when the summary is not relevant for the current user' do
        before do
          create(:ticket_article, :outbound_email, origin_by: agent, ticket:, body: 'This is a test article')
        end

        it 'receives new summary data' do
          TicketAIAssistanceSummarizeJob.new.perform(ticket, agent.locale)
          expect(mock_channel.mock_broadcasted_messages.first).to include(
            result: include(
              'data' => include(
                'ticketAIAssistanceSummaryUpdates' => include(
                  'summary'   => expected_broadcasted_summary,
                  'analytics' => {
                    'run'      => {
                      'id' => gql.id(ai_analytics_run),
                    },
                    'usage'    => nil,
                    'isUnread' => false,
                  },
                )
              )
            )
          )
        end

        context 'when user has already added usage' do
          before do
            create(:ai_analytics_usage, ai_analytics_run: ai_analytics_run, user: agent, rating:)
          end

          context 'when user added no rating yet' do
            let(:rating) { nil }

            it 'returns cached version with usage info' do
              TicketAIAssistanceSummarizeJob.new.perform(ticket, agent.locale)
              expect(mock_channel.mock_broadcasted_messages.first).to include(
                result: include(
                  'data' => include(
                    'ticketAIAssistanceSummaryUpdates' => include(
                      'summary'   => expected_broadcasted_summary,
                      'analytics' => {
                        'run'      => {
                          'id' => gql.id(ai_analytics_run),
                        },
                        'usage'    => {
                          'userHasProvidedFeedback' => false
                        },
                        'isUnread' => false,
                      }
                    )
                  )
                )
              )
            end
          end

          context 'when usage added rating too' do
            let(:rating) { false }

            it 'returns cached version with usage info' do
              TicketAIAssistanceSummarizeJob.new.perform(ticket, agent.locale)
              expect(mock_channel.mock_broadcasted_messages.first).to include(
                result: include(
                  'data' => include(
                    'ticketAIAssistanceSummaryUpdates' => include(
                      'summary'   => expected_broadcasted_summary,
                      'analytics' => {
                        'run'      => { 'id' => gql.id(ai_analytics_run) },
                        'usage'    => {
                          'userHasProvidedFeedback' => true,
                        },
                        'isUnread' => false,
                      }
                    )
                  )
                )
              )
            end
          end
        end
      end
    end
  end
end
