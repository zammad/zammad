# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Subscriptions::TicketUpdates, type: :graphql do
  let(:agent)        { create(:agent) }
  let(:ticket)       { create(:ticket) }
  let(:variables)    { { ticketId: gql.id(ticket) } }
  let(:mock_channel) { build_mock_channel }
  let(:subscription) do
    <<~QUERY
      subscription ticketUpdates($ticketId: ID!) {
        ticketUpdates(ticketId: $ticketId) {
          ticket {
            id
            internalId
            title
          }
          ticketArticle {
            id
            subject
          }
        }
      }
    QUERY
  end

  before do
    gql.execute(subscription, variables: variables, context: { channel: mock_channel })
  end

  context 'with an agent', authenticated_as: :agent do
    context 'with permission' do
      let(:agent) { create(:agent, groups: [ticket.group]) }

      it 'subscribes' do
        expect(gql.result.data).to eq({ 'ticket' => nil, 'ticketArticle' => nil })
      end

      it 'receives ticket updates' do
        ticket.save!

        expect(mock_channel.mock_broadcasted_messages.first[:result]['data']['ticketUpdates']['ticket']['title']).to eq(ticket.title)
      end

      context 'when a new article is created', :aggregate_failures do
        it 'receives ticket updates' do
          article = create(:ticket_article,
                           ticket:  ticket,
                           subject: 'subcription test',
                           from:    'no-reply@zammad.com')

          article.internal = !article.internal
          article.save!

          expect(mock_channel.mock_broadcasted_messages.count).to be(2)
          expect(mock_channel.mock_broadcasted_messages.first[:result]['data']['ticketUpdates']['ticket']['title']).to eq(ticket.title)
          expect(mock_channel.mock_broadcasted_messages.last[:result]['data']['ticketUpdates']['ticketArticle']['subject']).to eq(article.subject)
        end
      end

      context 'when the group is changed and permission is lost' do
        it 'does stop receiving ticket updates' do
          ticket.update!(group: create(:group))

          expect(mock_channel.mock_broadcasted_messages.first[:result]).to include(
            {
              'data'   => nil,
              'errors' => include(
                include(
                  'message' => 'not allowed to show? this Ticket',
                ),
              ),
            }
          )
        end
      end

      context 'without ticket' do
        let(:ticket) { create(:ticket).tap(&:destroy) }

        it 'fetches no ticket' do
          expect(gql.result.error_type).to eq(ActiveRecord::RecordNotFound)
        end
      end
    end

    context 'without permission' do
      it 'raises authorization error' do
        expect(gql.result.error_type).to eq(Exceptions::Forbidden)
      end
    end

    it_behaves_like 'graphql responds with error if unauthenticated'
  end
end
