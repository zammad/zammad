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
            title
            articleCount
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
        expect(gql.result.data).to eq({ 'ticket' => nil })
      end

      it 'receives ticket updates' do
        ticket.save!

        expect(mock_channel.mock_broadcasted_messages.first[:result]['data']['ticketUpdates']['ticket']['title']).to eq(ticket.title)
      end

      context 'when a new article is created', :aggregate_failures do
        before do
          create(:ticket_article, ticket: ticket, subject: 'subscription test', from: 'no-reply@zammad.com')
        end

        it 'receives ticket update message' do
          expect(mock_channel.mock_broadcasted_messages).to eq(
            [ { result: { 'data' => { 'ticketUpdates' => { 'ticket' => { 'title' => 'Test Ticket', 'articleCount' => 1 } } } }, more: true } ]
          )
        end
      end

      context 'when an article is removed', :aggregate_failures do
        before do
          create(:ticket_article, ticket: ticket, subject: 'subcription test', from: 'no-reply@zammad.com').tap do |article|
            mock_channel.mock_broadcasted_messages.clear
            article.destroy!
          end
        end

        it 'receives article remove push message' do
          expect(mock_channel.mock_broadcasted_messages).to eq(
            [ { result: { 'data' => { 'ticketUpdates' => { 'ticket' => { 'title' => 'Test Ticket', 'articleCount' => 0 } } } }, more: true } ]
          )
        end
      end

      context 'when the group is changed and permission is lost' do
        it 'does stop receiving ticket updates' do
          ticket.update!(group: create(:group))
          expect(mock_channel.mock_broadcasted_messages.first[:result]['errors'].first['message']).to eq('not allowed to show? this Ticket')
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
