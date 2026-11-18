# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Queries::Ticket::ExternalReferences::IdoitUpObjectList, type: :graphql do
  let(:variables)           { { ticketId: gql.id(ticket) } }
  let(:ticket)              { create(:ticket, preferences: { idoit_up: { object_ids: ['00000000Test0026'] } }) }

  let(:query) do
    <<~QUERY
      query ticketExternalReferencesIdoitUpObjectList(
        $ticketId: ID
        $idoitUpObjectIds: [String!]
      ) {
        ticketExternalReferencesIdoitUpObjectList(
          input: {
            ticketId: $ticketId
            idoitUpObjectIds: $idoitUpObjectIds
          }
        ) {
          idoitUpObjectId
          title
          link
          type
          status
        }
      }
    QUERY
  end

  let(:idoit_up_api_object) { { 'id' => '00000000Test0026', 'cmdb_status_title' => 'in operation', 'title' => 'Test', 'type_title' => 'Building', 'link' => 'http://idoit-up.example/object/00000000Test0026' } }
  let(:idoit_up_object)             { { 'idoitUpObjectId' => '00000000Test0026', 'status' => 'in operation', 'title' => 'Test', 'type' => 'Building', 'link' => 'http://idoit-up.example/object/00000000Test0026' } }
  let(:idoit_up_integration_active) { true }

  context 'with an agent', authenticated_as: :agent do
    let(:agent) { create(:agent, groups: [ticket.group]) }

    before do
      Setting.set('idoit_up_integration', idoit_up_integration_active)
      allow(IdoitUp).to receive(:query).with('cmdb.objects', { ids: ['00000000Test0026'] }, user: anything).and_return({ 'result' => [idoit_up_api_object] })
      gql.execute(query, variables: variables)
    end

    context 'when i-doit up integration is inactive' do
      let(:idoit_up_integration_active) { false }

      it 'raises an error' do
        expect(gql.result.error_type).to eq(Exceptions::Forbidden)
      end
    end

    context 'when ticket is used' do
      it 'returns i-doit up objects', aggregate_failures: true do
        expect(gql.result.data).to eq([idoit_up_object])
      end
    end

    context 'when i-doit up object ids are used' do
      let(:variables) { { idoitUpObjectIds: ['00000000Test0026'] } }

      it 'returns i-doit up objects', aggregate_failures: true do
        expect(gql.result.data).to eq([idoit_up_object])
      end
    end

    context 'when no input is provided' do
      let(:variables) { {} }

      it 'raises a validation error' do
        expect(gql.result.error_type).to eq(GraphQL::Schema::Validator::ValidationFailedError)
      end
    end
  end

  context 'when unauthenticated' do
    before do
      Setting.set('idoit_up_integration', true)
      gql.execute(query, variables: variables)
    end

    it_behaves_like 'graphql responds with error if unauthenticated'
  end
end
