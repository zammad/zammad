# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Queries::Ticket::ExternalReferences::IdoitUpObjectSearch, type: :graphql do
  let(:idoit_up_type_id)    { '3' }
  let(:search_query)        { '' }
  let(:limit)               { 3 }
  let(:variables)           { { idoitUpTypeId: idoit_up_type_id, query: search_query, limit: } }

  let(:query) do
    <<~QUERY
      query ticketExternalReferencesIdoitUpObjectSearch(
        $idoitUpTypeId: String
        $query: String
        $limit: Int
      ) {
        ticketExternalReferencesIdoitUpObjectSearch(
          idoitUpTypeId: $idoitUpTypeId
          query: $query
          limit: $limit
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
    let(:agent) { create(:agent) }

    before do
      setup if defined? setup
      Setting.set('idoit_up_integration', idoit_up_integration_active)
      gql.execute(query, variables: variables)
    end

    context 'when i-doit up integration is inactive' do
      let(:idoit_up_integration_active) { false }

      it 'raises an error' do
        expect(gql.result.error_type).to eq(Exceptions::Forbidden)
      end
    end

    context 'without type and search query' do
      let(:variables) { {} }
      let(:setup) do
        allow(IdoitUp).to receive(:query).with('cmdb.objects', {}, user: anything).and_return({ 'result' => [idoit_up_api_object] })
      end

      it 'returns i-doit up objects', aggregate_failures: true do
        expect(gql.result.data).to eq([idoit_up_object])
      end
    end

    context 'without search query' do
      let(:setup) do
        allow(IdoitUp).to receive(:query).with('cmdb.objects', { 'type' => '3' }, user: anything).and_return({ 'result' => [idoit_up_api_object] })
      end

      it 'returns i-doit up objects', aggregate_failures: true do
        expect(gql.result.data).to eq([idoit_up_object])
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
        allow(IdoitUp).to receive(:query).with('cmdb.objects', { 'type' => '3', 'title' => '%Test%' }, user: anything).and_return({ 'result' => [idoit_up_api_object] })
      end

      it 'returns i-doit up objects', aggregate_failures: true do
        expect(gql.result.data).to eq([idoit_up_object])
      end
    end

    context 'with nonmatching search query' do
      let(:search_query) { 'nonexisting' }

      let(:setup) do
        allow(IdoitUp).to receive(:query).with('cmdb.objects', { 'type' => '3', 'title' => '%nonexisting%' }, user: anything).and_return({ 'result' => [] })
      end

      it 'returns no objects', aggregate_failures: true do
        expect(gql.result.data).to eq([])
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
