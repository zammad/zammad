# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Mutations::Ticket::ExternalReferences::IdoitObjectAdd, type: :graphql do
  let(:variables)                { { ticketId: gql.id(ticket), idoitObjectIds: idoit_object_ids } }
  let(:ticket)                   { create(:ticket, preferences: { idoit: { object_ids: [42] } }) }
  let(:idoit_object_ids)         { [26] }
  let(:idoit_api_object)         { { 'id' => 26, 'cmdb_status_title' => 'in operation', 'title' => 'Test', 'type_title' => 'Building', 'link' => 'http://idoit.example/?objID=26' } }
  let(:idoit_object)             { { 'idoitObjectId' => 26, 'status' => 'in operation', 'title' => 'Test', 'type' => 'Building', 'link' => 'http://idoit.example/?objID=26' } }
  let(:idoit_integration_active) { true }

  let(:mutation) do
    <<~MUTATION
      mutation ticketExternalReferencesIdoitObjectAdd(
        $ticketId: ID
        $idoitObjectIds: [Int!]!
      ) {
        ticketExternalReferencesIdoitObjectAdd(
          ticketId: $ticketId
          idoitObjectIds: $idoitObjectIds
        ) {
          idoitObjects {
            idoitObjectId
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
    Setting.set('idoit_integration', idoit_integration_active)
    allow(Idoit).to receive(:query).with('cmdb.objects', { ids: [ 26 ] }).and_return({ 'result' => [idoit_api_object] })
  end

  context 'with an agent', authenticated_as: :agent do
    let(:agent) { create(:agent) }

    context 'when idoit integration is inactive' do
      let(:idoit_integration_active) { false }

      it 'raises an error' do
        gql.execute(mutation, variables: variables)
        expect(gql.result.error_type).to eq(Exceptions::Forbidden)
      end
    end

    context 'when ticket is used' do
      context 'when an agent has access to the ticket' do
        let(:agent) { create(:agent, groups: [ticket.group]) }

        context 'when the idoit object id already exists' do
          before do
            ticket.preferences[:idoit] = { object_ids: [26] }
            ticket.save!
          end

          it 'returns a user error' do
            gql.execute(mutation, variables: variables)

            expect(gql.result.data[:errors].first).to include('field' => 'idoit_object_ids', 'message' => 'The idoit object is already present on the ticket.')
          end
        end

        context 'when new idoit object should be added' do

          it 'returns the idoit object', aggregate_failures: true do
            gql.execute(mutation, variables: variables)

            expect(gql.result.data[:idoitObjects]).to contain_exactly(idoit_object)

            expect(ticket.reload.preferences)
              .to include(idoit: { object_ids: [42, 26] })
          end
        end
      end

      context 'when an agent has no access to the ticket' do
        before { gql.execute(mutation, variables:) }

        it_behaves_like 'graphql responds with error if unauthenticated'
      end
    end

    context 'without a ticket' do
      let(:variables) { { idoitObjectIds: [26] } }

      context 'when new idoit object should be added' do

        it 'returns idoit object', aggregate_failures: true do
          gql.execute(mutation, variables: variables)

          expect(gql.result.data[:idoitObjects]).to contain_exactly(idoit_object)
        end
      end
    end
  end

  context 'when unauthenticated' do
    before { gql.execute(mutation, variables:) }

    it_behaves_like 'graphql responds with error if unauthenticated'
  end
end
