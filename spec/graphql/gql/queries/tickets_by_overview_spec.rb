# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Queries::TicketsByOverview, type: :graphql do

  context 'when fetching ticket overviews' do
    let(:agent)     { create(:agent) }
    let(:query)     do
      gql.read_files('apps/mobile/modules/ticket/graphql/queries/ticketsByOverview.graphql', 'shared/graphql/fragments/objectAttributeValues.graphql')
    end
    let(:variables) { { overviewId: gql.id(overview) } }
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
