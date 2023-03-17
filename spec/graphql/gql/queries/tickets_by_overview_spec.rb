# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Queries::TicketsByOverview, type: :graphql do

  context 'when fetching ticket overviews' do
    let(:agent)     { create(:agent) }
    let(:query)     do
      <<~QUERY
        query ticketsByOverview(
          $overviewId: ID!
          $orderBy: String
          $orderDirection: EnumOrderDirection
          $cursor: String
          $pageSize: Int = 10
        ) {
          ticketsByOverview(
            overviewId: $overviewId
            orderBy: $orderBy
            orderDirection: $orderDirection
            after: $cursor
            first: $pageSize
          ) {
            totalCount
            edges {
              node {
                id
                internalId
                number
              }
            }
          }
        }
      QUERY
    end
    let(:variables) { { overviewId: gql.id(overview), showPriority: true, showUpdatedBy: true } }
    let(:overview)    { Overview.find_by(link: 'all_unassigned') }
    let!(:ticket)     { create(:ticket) }

    before do
      gql.execute(query, variables: variables)
    end

    context 'with an agent', authenticated_as: :agent do
      context 'with visible tickets' do
        let(:agent) { create(:agent, groups: [ticket.group]) }

        it 'fetches a ticket' do
          expect(gql.result.nodes.first).to include('number' => ticket.number)
        end

        it 'has total_count' do
          expect(gql.result.data['totalCount']).to eq(1)
        end
      end

      context 'without visible tickets' do
        it 'fetches no ticket' do
          expect(gql.result.nodes).to eq([])
        end

        it 'has total_count' do
          expect(gql.result.data['totalCount']).to be_zero
        end
      end
    end

    context 'with a customer', authenticated_as: :customer do
      let(:customer) { create(:customer) }

      it 'raises authorization error' do
        expect(gql.result.error_type).to eq(Exceptions::Forbidden)
      end
    end

    it_behaves_like 'graphql responds with error if unauthenticated'
  end
end
