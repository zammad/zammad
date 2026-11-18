# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Mutations::Ticket::ExternalReferences::IdoitUpObjectAdd, type: :graphql do
  let(:variables)                   { { ticketId: gql.id(ticket), idoitUpObjectIds: idoit_up_object_ids } }
  let(:ticket)                      { create(:ticket, preferences: { idoit_up: { object_ids: ['00000000Test0042'] } }) }
  let(:idoit_up_object_ids)         { ['00000000Test0026'] }
  let(:idoit_up_api_object)         { { 'id' => '00000000Test0026', 'cmdb_status_title' => 'in operation', 'title' => 'Test', 'type_title' => 'Building', 'link' => 'http://idoit-up.example/object/00000000Test0026' } }
  let(:idoit_up_object)             { { 'idoitUpObjectId' => '00000000Test0026', 'status' => 'in operation', 'title' => 'Test', 'type' => 'Building', 'link' => 'http://idoit-up.example/object/00000000Test0026' } }
  let(:idoit_up_integration_active) { true }

  let(:mutation) do
    <<~MUTATION
      mutation ticketExternalReferencesIdoitUpObjectAdd(
        $ticketId: ID
        $idoitUpObjectIds: [String!]!
      ) {
        ticketExternalReferencesIdoitUpObjectAdd(
          ticketId: $ticketId
          idoitUpObjectIds: $idoitUpObjectIds
        ) {
          idoitUpObjects {
            idoitUpObjectId
            title
            type
            status
            link
          }
          errors {
            message
            field
          }
        }
      }
    MUTATION
  end

  before do
    Setting.set('idoit_up_integration', idoit_up_integration_active)
    allow(IdoitUp).to receive(:query).with('cmdb.objects', { ids: ['00000000Test0026'] }, user: anything).and_return({ 'result' => [idoit_up_api_object] })
  end

  context 'with an agent', authenticated_as: :agent do
    let(:agent) { create(:agent) }

    context 'when i-doit up integration is inactive' do
      let(:idoit_up_integration_active) { false }

      it 'raises an error' do
        gql.execute(mutation, variables: variables)
        expect(gql.result.error_type).to eq(Exceptions::Forbidden)
      end
    end

    context 'when ticket is used' do
      context 'when an agent has access to the ticket' do
        let(:agent) { create(:agent, groups: [ticket.group]) }

        context 'when the i-doit up object id already exists' do
          before do
            ticket.preferences[:idoit_up] = { object_ids: ['00000000Test0026'] }
            ticket.save!
          end

          it 'returns a user error' do
            gql.execute(mutation, variables: variables)

            expect(gql.result.data[:errors].first).to include('field' => 'idoit_up_object_ids', 'message' => 'The i-doit up object is already present on the ticket.')
          end
        end

        context 'when new i-doit up object should be added' do

          it 'returns the i-doit up object', aggregate_failures: true do
            gql.execute(mutation, variables: variables)

            expect(gql.result.data[:idoitUpObjects]).to contain_exactly(idoit_up_object)

            expect(ticket.reload.preferences)
              .to include(idoit_up: { object_ids: %w[00000000Test0042 00000000Test0026] })
          end
        end
      end

      context 'when an agent has no access to the ticket' do
        before { gql.execute(mutation, variables:) }

        it_behaves_like 'graphql responds with forbidden'
      end
    end

    context 'without a ticket' do
      let(:variables) { { idoitUpObjectIds: ['00000000Test0026'] } }

      context 'when new i-doit up object should be added' do

        it 'returns i-doit up object', aggregate_failures: true do
          gql.execute(mutation, variables: variables)

          expect(gql.result.data[:idoitUpObjects]).to contain_exactly(idoit_up_object)
        end
      end
    end
  end

  context 'when unauthenticated' do
    before { gql.execute(mutation, variables:) }

    it_behaves_like 'graphql responds with error if unauthenticated'
  end
end
