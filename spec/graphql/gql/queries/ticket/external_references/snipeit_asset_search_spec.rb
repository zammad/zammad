# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Queries::Ticket::ExternalReferences::SnipeitAssetSearch, type: :graphql do
  let(:category_id)  { '3' }
  let(:search_query) { '' }
  let(:limit)        { 3 }
  let(:variables)    { { categoryId: category_id, query: search_query, limit: } }

  let(:query) do
    <<~QUERY
      query ticketExternalReferencesSnipeitAssetSearch(
        $categoryId: String
        $modelId: String
        $query: String
        $limit: Int
      ) {
        ticketExternalReferencesSnipeitAssetSearch(
          categoryId: $categoryId
          modelId: $modelId
          query: $query
          limit: $limit
        ) {
          snipeitAssetId
          name
          link
          model
          status
          category
          location
          assetTag
          serial
        }
      }
    QUERY
  end

  let(:snipeit_api_asset) do
    {
      'id'           => 26,
      'name'         => 'Laptop-001',
      'asset_tag'    => 'LAP001',
      'serial'       => 'ABC123',
      'link'         => 'http://snipeit.example/hardware/26',
      'model'        => { 'name' => 'MacBook Pro' },
      'status_label' => { 'name' => 'Ready to Deploy' },
      'category'     => { 'name' => 'Laptops' },
      'location'     => { 'name' => 'HQ' },
    }
  end
  let(:snipeit_asset) do
    {
      'snipeitAssetId' => 26,
      'name'           => 'Laptop-001',
      'assetTag'       => 'LAP001',
      'serial'         => 'ABC123',
      'link'           => 'http://snipeit.example/hardware/26',
      'model'          => 'MacBook Pro',
      'status'         => 'Ready to Deploy',
      'category'       => 'Laptops',
      'location'       => 'HQ',
    }
  end
  let(:snipeit_integration_active) { true }

  context 'with an agent', authenticated_as: :agent do
    let(:agent) { create(:agent) }

    before do
      setup if defined? setup
      Setting.set('snipeit_integration', snipeit_integration_active)
      gql.execute(query, variables: variables)
    end

    context 'when snipeit integration is inactive' do
      let(:snipeit_integration_active) { false }

      it 'raises an error' do
        expect(gql.result.error_type).to eq(Exceptions::Forbidden)
      end
    end

    context 'without category and search query' do
      let(:variables) { {} }
      let(:setup) do
        allow(Snipeit).to receive(:query).with('hardware', { 'limit' => 10 }).and_return({ 'rows' => [snipeit_api_asset] })
      end

      it 'returns snipeit assets', aggregate_failures: true do
        expect(gql.result.data).to eq([snipeit_asset])
      end
    end

    context 'without search query' do
      let(:setup) do
        allow(Snipeit).to receive(:query).with('hardware', { 'limit' => 3, 'category_id' => '3' }).and_return({ 'rows' => [snipeit_api_asset] })
      end

      it 'returns snipeit assets', aggregate_failures: true do
        expect(gql.result.data).to eq([snipeit_asset])
      end
    end

    context 'with matching search query' do
      let(:search_query) { 'Laptop' }

      let(:setup) do
        allow(Snipeit).to receive(:query).with('hardware', { 'limit' => 3, 'category_id' => '3', 'search' => 'Laptop' }).and_return({ 'rows' => [snipeit_api_asset] })
      end

      it 'returns snipeit assets', aggregate_failures: true do
        expect(gql.result.data).to eq([snipeit_asset])
      end
    end

    context 'with nonmatching search query' do
      let(:search_query) { 'nonexisting' }

      let(:setup) do
        allow(Snipeit).to receive(:query).with('hardware', { 'limit' => 3, 'category_id' => '3', 'search' => 'nonexisting' }).and_return({ 'rows' => [] })
      end

      it 'returns no assets', aggregate_failures: true do
        expect(gql.result.data).to eq([])
      end
    end
  end

  context 'when unauthenticated' do
    before do
      Setting.set('snipeit_integration', true)
      gql.execute(query, variables: variables)
    end

    it_behaves_like 'graphql responds with error if unauthenticated'
  end
end
