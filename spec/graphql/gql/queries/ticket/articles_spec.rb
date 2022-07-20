# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Queries::Ticket::Articles, type: :graphql do

  context 'when fetching tickets' do
    let(:agent)     { create(:agent) }
    let(:query)     do
      read_graphql_file('apps/mobile/modules/ticket/graphql/queries/ticket/articles.graphql')
    end
    let(:variables) { { ticketId: Gql::ZammadSchema.id_from_object(ticket) } }
    let(:customer)             { create(:customer) }
    let(:ticket)               { create(:ticket, customer: customer) }
    let!(:articles)            { create_list(:ticket_article, 5, :outbound_email, ticket: ticket) }
    let!(:internal_article)    { create(:ticket_article, :outbound_email, ticket: ticket, internal: true) }
    let(:response_articles)    { graphql_response['data']['ticketArticles']['edges'].map { |edge| edge['node'] } }
    let(:response_total_count) { graphql_response['data']['ticketArticles']['totalCount'] }

    before do
      graphql_execute(query, variables: variables)
    end

    context 'with an agent', authenticated_as: :agent do

      context 'with permission' do
        let(:agent) { create(:agent, groups: [ticket.group]) }
        let(:article1) { articles.first }
        let(:expected_article1) do
          {
            'subject'    => article1.subject,
            'from'       => article1.from,
            'to'         => article1.to,
            'references' => article1.references,
            'type'       => {
              'name' => article1.type.name,
            },
            'sender'     => {
              'name' => article1.sender.name,
            },
          }
        end

        it 'finds public and internal articles' do
          expect(response_total_count).to eq(articles.count + 1)
        end

        it 'finds article content' do
          expect(response_articles.first).to include(expected_article1)
        end

        context 'with ticketInternalId' do
          let(:variables) { { ticketInternalId: ticket.id } }

          it 'finds articles' do
            expect(response_total_count).to eq(articles.count + 1)
          end
        end

        context 'with ticketNumber' do
          let(:variables) { { ticketNumber: ticket.number } }

          it 'finds articles' do
            expect(response_total_count).to eq(articles.count + 1)
          end
        end
      end

      context 'without permission' do
        it 'raises authorization error' do
          expect(graphql_response['errors'][0]['extensions']['type']).to eq('Exceptions::Forbidden')
        end
      end

      context 'without ticket' do
        let(:ticket)   { create(:ticket).tap(&:destroy) }
        let(:articles)         { [] }
        let(:internal_article) { [] }

        it 'fetches no ticket' do
          expect(graphql_response['errors'][0]['extensions']['type']).to eq('ActiveRecord::RecordNotFound')
        end
      end
    end

    context 'with an customer', authenticated_as: :customer do
      it 'finds only public articles' do
        expect(response_total_count).to eq(articles.count)
      end

      it 'does not find internal articles' do
        expect(response_articles.pluck(:id)).to not_include(internal_article.id)
      end
    end

    it_behaves_like 'graphql responds with error if unauthenticated'
  end
end
