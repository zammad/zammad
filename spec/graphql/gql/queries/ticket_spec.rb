# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Queries::Ticket, type: :graphql do

  context 'when fetching tickets' do
    let(:agent)     { create(:agent) }
    let(:query)     do
      read_graphql_file('apps/mobile/modules/ticket/graphql/queries/ticket.graphql') +
        read_graphql_file('shared/graphql/fragments/objectAttributeValues.graphql')
    end
    let(:variables) { { ticketId: Gql::ZammadSchema.id_from_object(ticket) } }
    let(:ticket)    { create(:ticket) }

    before do
      graphql_execute(query, variables: variables)
    end

    context 'with an agent', authenticated_as: :agent do
      context 'with permission' do
        let(:agent) { create(:agent, groups: [ticket.group]) }

        shared_examples 'finds the ticket' do
          it 'finds the ticket' do
            expect(graphql_response['data']['ticket']).to include(
              'id'         => Gql::ZammadSchema.id_from_object(ticket),
              'internalId' => ticket.id,
              'number'     => ticket.number,
            )
          end
        end

        context 'when fetching a ticket by ticketId' do
          include_examples 'finds the ticket'
        end

        context 'when fetching a ticket by ticketInternalId' do
          let(:variables) { { ticketInternalId: ticket.id } }

          include_examples 'finds the ticket'
        end

        context 'when fetching a ticket by ticketNumber' do
          let(:variables) { { ticketNumber: ticket.number } }

          include_examples 'finds the ticket'
        end

        context 'when locator is missing' do
          let(:variables) { {} }

          it 'raises an exception' do
            expect(graphql_response['errors'][0]['extensions']['type']).to eq('RuntimeError')
          end
        end
      end

      context 'without permission' do
        it 'raises authorization error' do
          expect(graphql_response['errors'][0]['extensions']['type']).to eq('Exceptions::Forbidden')
        end
      end

      context 'without ticket' do
        let(:ticket) { create(:ticket).tap(&:destroy) }

        it 'fetches no ticket' do
          expect(graphql_response['errors'][0]['extensions']['type']).to eq('ActiveRecord::RecordNotFound')
        end
      end
    end

    it_behaves_like 'graphql responds with error if unauthenticated'
  end
end
