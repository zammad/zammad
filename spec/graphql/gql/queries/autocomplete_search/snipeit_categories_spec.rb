# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Queries::AutocompleteSearch::SnipeitCategories, authenticated_as: :agent, type: :graphql do

  let(:available_categories) { %w[Laptops Monitors Desktops Printers Phones] }
  let(:categories_api_result) do
    {
      'rows' => available_categories.each_with_index.map { |category, index| { 'id' => index + 1, 'name' => category } }
    }
  end

  context 'when searching for snipeit categories' do
    let(:agent) { create(:agent) }
    let(:query) do
      <<~QUERY
        query autocompleteSearchSnipeitCategories($input: AutocompleteSearchInput!)  {
          autocompleteSearchSnipeitCategories(input: $input) {
            value
            label
          }
        }
      QUERY
    end
    let(:variables)                  { { input: { query: query_string, limit: limit } } }
    let(:query_string)               { '' }
    let(:limit)                      { nil }
    let(:snipeit_integration_active) { true }

    before do
      Setting.set('snipeit_integration', snipeit_integration_active)
      allow(Snipeit).to receive(:query).and_return(categories_api_result)
      gql.execute(query, variables: variables)
    end

    context 'when snipeit integration is disabled' do
      let(:snipeit_integration_active) { false }

      it 'raises an error' do
        expect(gql.result.error_type).to eq(Exceptions::Forbidden)
      end
    end

    context 'without limit' do
      it 'returns all categories the API sent' do
        expect(gql.result.data.length).to eq(available_categories.length)
      end

      it 'asks the API for asset categories with the default limit' do
        expect(Snipeit).to have_received(:query).with('categories', { 'limit' => 10, 'category_type' => 'asset' })
      end
    end

    context 'with limit' do
      let(:limit) { 1 }

      it 'passes the limit on to the API' do
        expect(Snipeit).to have_received(:query).with('categories', hash_including('limit' => limit))
      end
    end

    context 'with search' do
      let(:query_string) { 'Laptops' }

      it 'lets the API filter instead of filtering the fetched page in Ruby' do
        expect(Snipeit).to have_received(:query).with('categories', hash_including('search' => 'Laptops'))
      end

      it 'maps the API rows to autocomplete entries' do
        expect(gql.result.data.first).to eq({ 'value' => '1', 'label' => 'Laptops' })
      end
    end

    context 'with a wildcard search' do
      let(:query_string) { '*' }

      it 'sends no search term' do
        expect(Snipeit).to have_received(:query).with('categories', { 'limit' => 10, 'category_type' => 'asset' })
      end
    end

    context 'when the API fails' do
      before do
        allow(Snipeit).to receive(:query).and_raise('API down')
        gql.execute(query, variables: variables)
      end

      it 'returns no entries instead of an error' do
        expect(gql.result.data).to eq([])
      end
    end

    it_behaves_like 'graphql responds with error if unauthenticated'
  end
end
