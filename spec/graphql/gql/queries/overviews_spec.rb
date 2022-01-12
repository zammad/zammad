# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Queries::Overviews, type: :graphql do

  context 'when fetching locales' do
    let(:agent) { create(:agent) }
    let(:query) { read_graphql_file('common/graphql/queries/overviews.graphql') }
    let(:variables) { { withTicketCount: false } }

    before do
      graphql_execute(query, variables: variables)
    end

    context 'with an agent', authenticated_as: :agent do
      it 'has agent overview' do
        expect(graphql_response['data']['overviews']['edges'][0]['node']).to include('name' => 'My assigned Tickets', 'link' => 'my_assigned', 'prio' => 1000, 'active' => true,)
      end

      context 'without ticket count' do
        it 'does not include ticketCount field' do
          expect(graphql_response['data']['overviews']['edges'][0]['node']).not_to have_key('ticketCount')
        end
      end

      context 'with ticket count' do
        let(:variables) { { withTicketCount: true } }

        it 'includes ticketCount field' do
          expect(graphql_response['data']['overviews']['edges'][0]['node']['ticketCount']).to eq(0)
        end
      end
    end

    context 'with a customer', authenticated_as: :customer do
      let(:customer) { create(:customer) }

      it 'has customer overview' do
        expect(graphql_response['data']['overviews']['edges'][0]['node']).to include('name' => 'My Tickets', 'link' => 'my_tickets', 'prio' => 1100, 'active' => true,)
      end
    end

    include_examples 'graphql responds with error if unauthenticated'
  end
end
