# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Queries::Ticket::ExternalReferences::IdoitObjectList, type: :graphql do
  let(:variables)           { { ticketId: gql.id(ticket) } }
  let(:ticket)              { create(:ticket, preferences: { idoit: { object_ids: [26] } }) }

  let(:query) do
    <<~QUERY
      query ticketExternalReferencesIdoitObjectList(
        $ticketId: ID
        $idoitObjectIds: [Int!]
      ) {
        ticketExternalReferencesIdoitObjectList(
          input: {
            ticketId: $ticketId
            idoitObjectIds: $idoitObjectIds
          }
        ) {
          idoitObjectId
          title
          link
          type
          status
        }
      }
    QUERY
  end

  let(:idoit_api_object) { { 'id' => 26, 'cmdb_status_title' => 'in operation', 'title' => 'Test', 'type_title' => 'Building', 'link' => 'http://idoit.example/?objID=26' } }
  let(:idoit_object)             { { 'idoitObjectId' => 26, 'status' => 'in operation', 'title' => 'Test', 'type' => 'Building', 'link' => 'http://idoit.example/?objID=26' } }
  let(:idoit_integration_active) { true }

  context 'with an agent', authenticated_as: :agent do
    let(:agent) { create(:agent, groups: [ticket.group]) }

    before do
      Setting.set('idoit_integration', idoit_integration_active)
      allow(Idoit).to receive(:query).with('cmdb.objects', { ids: [ 26 ] }).and_return({ 'result' => [idoit_api_object] })
      gql.execute(query, variables: variables)
    end

    context 'when idoit integration is inactive' do
      let(:idoit_integration_active) { false }

      it 'raises an error' do
        expect(gql.result.error_type).to eq(Exceptions::Forbidden)
      end
    end

    context 'when ticket is used' do
      it 'returns idoit objects', aggregate_failures: true do
        expect(gql.result.data).to eq([idoit_object])
      end
    end

    context 'when idoit object ids are used' do
      let(:variables) { { idoitObjectIds: [26] } }

      it 'returns idoit objects', aggregate_failures: true do
        expect(gql.result.data).to eq([idoit_object])
      end
    end

    context 'when no input is provided' do
      let(:variables) { {} }

      it 'returns idoit objects', aggregate_failures: true do
        expect(gql.result.error_type).to eq(GraphQL::Schema::Validator::ValidationFailedError)
      end
    end
  end

  context 'when unauthenticated' do
    before do
      Setting.set('idoit_integration', true)
      gql.execute(query, variables: variables)
    end

    it_behaves_like 'graphql responds with error if unauthenticated'
  end
end
