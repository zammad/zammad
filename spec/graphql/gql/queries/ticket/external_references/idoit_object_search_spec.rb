# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Queries::Ticket::ExternalReferences::IdoitObjectSearch, type: :graphql do
  let(:idoit_type_id)       { '3' }
  let(:search_query)        { '' }
  let(:limit)               { 3 }
  let(:variables)           { { idoitTypeId: idoit_type_id, query: search_query, limit: } }

  let(:query) do
    <<~QUERY
      query ticketExternalReferencesIdoitObjectSearch(
        $idoitTypeId: String
        $query: String
        $limit: Int
      ) {
        ticketExternalReferencesIdoitObjectSearch(
          idoitTypeId: $idoitTypeId
          query: $query
          limit: $limit
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
    let(:agent) { create(:agent) }

    before do
      setup if defined? setup
      Setting.set('idoit_integration', idoit_integration_active)
      gql.execute(query, variables: variables)
    end

    context 'when idoit integration is inactive' do
      let(:idoit_integration_active) { false }

      it 'raises an error' do
        expect(gql.result.error_type).to eq(Exceptions::Forbidden)
      end
    end

    context 'without type and search query' do
      let(:variables) { {} }
      let(:setup) do
        allow(Idoit).to receive(:query).with('cmdb.objects', {}).and_return({ 'result' => [idoit_api_object] })
      end

      it 'returns idoit objects', aggregate_failures: true do
        expect(gql.result.data).to eq([idoit_object])
      end
    end

    context 'without search query' do
      let(:setup) do
        allow(Idoit).to receive(:query).with('cmdb.objects', { 'type' => '3' }).and_return({ 'result' => [idoit_api_object] })
      end

      it 'returns idoit objects', aggregate_failures: true do
        expect(gql.result.data).to eq([idoit_object])
      end

      context 'with limit' do
        let(:limit) { 0 }

        it 'respects the limit' do
          expect(gql.result.data).to eq([])
        end
      end
    end

    context 'with matching search query' do
      let(:search_query) { 'Test' }

      let(:setup) do
        allow(Idoit).to receive(:query).with('cmdb.objects', { 'type' => '3', 'title' => '%Test%' }).and_return({ 'result' => [idoit_api_object] })
      end

      it 'returns idoit objects', aggregate_failures: true do
        expect(gql.result.data).to eq([idoit_object])
      end
    end

    context 'with nonmatching search query' do
      let(:search_query) { 'nonexisting' }

      let(:setup) do
        allow(Idoit).to receive(:query).with('cmdb.objects', { 'type' => '3', 'title' => '%nonexisting%' }).and_return({ 'result' => [] })
      end

      it 'returns no objects', aggregate_failures: true do
        expect(gql.result.data).to eq([])
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
