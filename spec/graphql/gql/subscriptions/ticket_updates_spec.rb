# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Subscriptions::TicketUpdates, type: :graphql do
  let(:agent)        { create(:agent) }
  let(:ticket)       { create(:ticket) }
  let(:variables)    { { ticketId: gql.id(ticket) } }
  let(:mock_channel) { build_mock_channel }
  let(:subscription) do
    gql.read_files(
      'apps/mobile/modules/ticket/graphql/subscriptions/ticketUpdates.graphql',
      'apps/mobile/modules/ticket/graphql/fragments/ticketAttributes.graphql',
      'apps/mobile/modules/ticket/graphql/fragments/ticketArticleAttributes.graphql',
      'shared/graphql/fragments/objectAttributeValues.graphql'
    )
  end

  before do
    gql.execute(subscription, variables: variables, context: { channel: mock_channel })
  end

  context 'with an agent', authenticated_as: :agent do
    context 'with permission' do
      let(:agent) { create(:agent, groups: [ticket.group]) }

      it 'subscribes' do
        expect(gql.result.data).to eq({ 'ticket' => nil })
      end

      it 'receives ticket updates' do
        ticket.save!

        expect(mock_channel.mock_broadcasted_messages.first[:result]['data']['ticketUpdates']['ticket']['title']).to eq(ticket.title)
      end

      context 'when a new article is created' do
        it 'receives ticket updates' do
          create(:ticket_article,
                 ticket:  ticket,
                 subject: 'subcription test',
                 from:    'no-reply@zammad.com')

          expect(mock_channel.mock_broadcasted_messages).not_to be_empty
        end
      end

      context 'when the group is changed and permission is lost' do
        it 'does stop receiving ticket updates' do # rubocop:disable RSpec/ExampleLength
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
