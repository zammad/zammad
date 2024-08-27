# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Subscriptions::TicketArticleUpdates, type: :graphql do
  let(:user)         { create(:agent) }
  let(:ticket)       { create(:ticket) }
  let(:variables)    { { ticketId: gql.id(ticket) } }
  let(:mock_channel) { build_mock_channel }
  let(:subscription) do
    <<~QUERY
      subscription ticketArticleUpdates($ticketId: ID!) {
        ticketArticleUpdates(ticketId: $ticketId) {
          addArticle {
            subject
          }
          updateArticle {
            subject
          }
          removeArticleId
        }
      }
    QUERY
  end

  before do
    gql.execute(subscription, variables: variables, context: { channel: mock_channel })
  end

  shared_examples 'check subscription handling with permission' do |is_customer:|
    it 'subscribes' do
      expect(gql.result.data).to eq({ 'addArticle' => nil, 'updateArticle' => nil, 'removeArticleId' => nil })
    end

    context 'when a new article is created', :aggregate_failures do
      before do
        create(:ticket_article, ticket: ticket, subject: 'subscription test', from: 'no-reply@zammad.com')
        create(:ticket_article, ticket: ticket, subject: 'subscription test internal', from: 'no-reply@zammad.com', internal: true)
      end

      let(:public_add_message) do
        {
          'addArticle'      => { 'subject' => 'subscription test' },
          'updateArticle'   => nil,
          'removeArticleId' => nil,
        }
      end
      let(:internal_add_message) do
        {
          'addArticle'      => { 'subject' => 'subscription test internal' },
          'updateArticle'   => nil,
          'removeArticleId' => nil,
        }
      end

      it 'receives article create push message' do
        if is_customer
          expect(mock_channel.mock_broadcasted_messages).to eq(
            [ { result: { 'data' => { 'ticketArticleUpdates' => public_add_message } }, more: true } ]
          )
        else
          expect(mock_channel.mock_broadcasted_messages).to eq(
            [
              { result: { 'data' => { 'ticketArticleUpdates' => public_add_message } }, more: true },
              { result: { 'data' => { 'ticketArticleUpdates' => internal_add_message } }, more: true },
            ]
          )
        end
      end
    end

    context 'when an article is updated', :aggregate_failures do
      before do
        create(:ticket_article, ticket: ticket, subject: 'subcription test', from: 'no-reply@zammad.com').tap do |article|
          mock_channel.mock_broadcasted_messages.clear
          article.subject = 'subscription test internal'
          article.internal = true
          article.save!
          article.subject = 'subscription test public'
          article.internal = false
          article.save!
        end
      end

      let(:internal_update_message) do
        {
          'addArticle'      => nil,
          'updateArticle'   => { 'subject' => 'subscription test internal' },
          'removeArticleId' => nil,
        }
      end
      let(:internal_remove_message) do
        {
          'addArticle'      => nil,
          'updateArticle'   => nil,
          'removeArticleId' => gql.id(Ticket::Article.last),
        }
      end
      let(:public_add_message) do
        {
          'addArticle'      => { 'subject' => 'subscription test public' },
          'updateArticle'   => nil,
          'removeArticleId' => nil,
        }
      end
      let(:public_update_message) do
        {
          'addArticle'      => nil,
          'updateArticle'   => { 'subject' => 'subscription test public' },
          'removeArticleId' => nil,
        }
      end

      it 'receives article update push message' do
        if is_customer
          expect(mock_channel.mock_broadcasted_messages).to eq(
            [
              { result: { 'data' => { 'ticketArticleUpdates' => internal_remove_message } }, more: true },
              { result: { 'data' => { 'ticketArticleUpdates' => public_add_message } }, more: true },
            ]
          )
        else
          expect(mock_channel.mock_broadcasted_messages).to eq(
            [
              { result: { 'data' => { 'ticketArticleUpdates' => internal_update_message } }, more: true },
              { result: { 'data' => { 'ticketArticleUpdates' => public_update_message } }, more: true },
            ]
          )
        end
      end
    end

    context 'when an article is removed', :aggregate_failures do
      let!(:article) do
        create(:ticket_article, ticket: ticket, subject: 'subcription test', from: 'no-reply@zammad.com').tap do |article|
          mock_channel.mock_broadcasted_messages.clear
          article.destroy!
        end
      end

      let(:remove_message) do
        {
          'addArticle'      => nil,
          'updateArticle'   => nil,
          'removeArticleId' => gql.id(article),
        }
      end

      it 'receives article remove push message' do
        expect(mock_channel.mock_broadcasted_messages).to eq(
          [ { result: { 'data' => { 'ticketArticleUpdates' => remove_message } }, more: true } ]
        )
      end
    end

    context 'when permission for the ticket is lost' do
      before do
        ticket.update!(group: create(:group), customer: create(:customer))
        create(:ticket_article, ticket: ticket, subject: 'subcription test', from: 'no-reply@zammad.com')
      end

      it 'does stop receiving ticket updates' do
        expect(mock_channel.mock_broadcasted_messages.first[:result]['errors'].first['message']).to eq('not allowed to TicketPolicy#show? this Ticket')
      end
    end

    context 'without ticket' do
      let(:ticket) { create(:ticket).tap(&:destroy) }

      it 'fetches no ticket' do
        expect(gql.result.error_type).to eq(ActiveRecord::RecordNotFound)
      end
    end
  end

  shared_examples 'check subscription handling without permission' do
    it 'raises authorization error' do
      expect(gql.result.error_type).to eq(Exceptions::Forbidden)
    end
  end

  context 'with an agent', authenticated_as: :agent do
    let(:user) { agent }

    context 'with permission' do
      let(:agent) { create(:agent, groups: [ticket.group]) }

      include_examples 'check subscription handling with permission', is_customer: false
    end

    context 'without permission' do
      let(:agent) { create(:agent) }

      include_examples 'check subscription handling without permission'
    end
  end

  context 'with a customer', authenticated_as: :customer do
    let(:user) { customer }

    context 'with permission' do
      let(:customer) { ticket.customer }

      include_examples 'check subscription handling with permission', is_customer: true
    end

    context 'without permission' do
      let(:customer) { create(:customer) }

      include_examples 'check subscription handling without permission'
    end
  end

  it_behaves_like 'graphql responds with error if unauthenticated'
end
