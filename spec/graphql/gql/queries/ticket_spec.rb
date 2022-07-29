# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Queries::Ticket, type: :graphql do

  context 'when fetching tickets' do
    let(:agent)     { create(:agent) }
    let(:query)     do
      gql.read_files(
        'apps/mobile/modules/ticket/graphql/queries/ticket.graphql',
        'apps/mobile/modules/ticket/graphql/fragments/ticketAttributes.graphql',
        'apps/mobile/modules/ticket/graphql/fragments/ticketArticleAttributes.graphql',
        'shared/graphql/fragments/objectAttributeValues.graphql'
      )
    end
    let(:variables) { { ticketId: gql.id(ticket) } }
    let(:ticket)    { create(:ticket) }

    before do
      gql.execute(query, variables: variables)
    end

    context 'with an agent', authenticated_as: :agent do
      context 'with permission' do
        let(:agent) { create(:agent, groups: [ticket.group]) }

        shared_examples 'finds the ticket' do
          it 'finds the ticket' do
            expect(gql.result.data).to include(
              'id'         => gql.id(ticket),
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
            expect(gql.result.error_type).to eq(GraphQL::Schema::Validator::ValidationFailedError)
          end
        end
      end

      context 'without permission' do
        it 'raises authorization error' do
          expect(gql.result.error_type).to eq(Exceptions::Forbidden)
        end
      end

      context 'without ticket' do
        let(:ticket) { create(:ticket).tap(&:destroy) }

        it 'fetches no ticket' do
          expect(gql.result.error_type).to eq(ActiveRecord::RecordNotFound)
        end
      end
    end

    it_behaves_like 'graphql responds with error if unauthenticated'
  end
end
