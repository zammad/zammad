# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Subscriptions::TicketArticleUpdates, type: :graphql do
  let(:agent)        { create(:agent) }
  let(:ticket)       { create(:ticket) }
  let(:variables)    { { ticketId: gql.id(ticket) } }
  let(:mock_channel) { build_mock_channel }
  let(:subscription) do
    <<~QUERY
      subscription ticketArticleUpdates($ticketId: ID!) {
        ticketArticleUpdates(ticketId: $ticketId) {
          createdArticle {
            subject
          }
          updatedArticle {
            subject
          }
          deletedArticleId
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
        expect(gql.result.data).to eq({ 'createdArticle' => nil, 'updatedArticle' => nil, 'deletedArticleId' => nil })
      end

      context 'when a new article is created', :aggregate_failures do
        before do
          create(:ticket_article, ticket: ticket, subject: 'subscription test', from: 'no-reply@zammad.com')
        end

        let(:article_create_message) do
          {
            'createdArticle'   => { 'subject' => 'subscription test' },
            'updatedArticle'   => nil,
            'deletedArticleId' => nil,
          }
        end

        it 'receives article create push message' do
          expect(mock_channel.mock_broadcasted_messages).to eq(
            [ { result: { 'data' => { 'ticketArticleUpdates' => article_create_message } }, more: true } ]
          )
        end
      end

      context 'when an article is updated', :aggregate_failures do
        before do
          create(:ticket_article, ticket: ticket, subject: 'subcription test', from: 'no-reply@zammad.com').tap do |article|
            mock_channel.mock_broadcasted_messages.clear
            article.subject = 'subscription test updated'
            article.save!
          end
        end

        let(:update_message) do
          {
            'createdArticle'   => nil,
            'updatedArticle'   => { 'subject' => 'subscription test updated' },
            'deletedArticleId' => nil,
          }
        end

        it 'receives article update push message' do
          expect(mock_channel.mock_broadcasted_messages).to eq(
            [ { result: { 'data' => { 'ticketArticleUpdates' => update_message } }, more: true } ]
          )
        end
      end

      context 'when an article is removed', :aggregate_failures do
        let!(:article) do
          create(:ticket_article, ticket: ticket, subject: 'subcription test', from: 'no-reply@zammad.com').tap do |article|
            mock_channel.mock_broadcasted_messages.clear
            article.destroy!
          end
        end

        let(:destroy_message) do
          {
            'createdArticle'   => nil,
            'updatedArticle'   => nil,
            'deletedArticleId' => gql.id(article),
          }
        end

        it 'receives article remove push message' do
          expect(mock_channel.mock_broadcasted_messages).to eq(
            [ { result: { 'data' => { 'ticketArticleUpdates' => destroy_message } }, more: true } ]
          )
        end
      end

      context 'when the group is changed and permission is lost' do
        before do
          ticket.update!(group: create(:group))
          create(:ticket_article, ticket: ticket, subject: 'subcription test', from: 'no-reply@zammad.com')
        end

        it 'does stop receiving ticket updates' do
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
