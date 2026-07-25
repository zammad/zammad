# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Queries::AutocompleteSearch::SnipeitModels, authenticated_as: :agent, type: :graphql do

  let(:available_models) { ['MacBook Pro', 'ThinkPad', 'UltraSharp', 'DeskJet', 'iPhone'] }
  let(:models_api_result) do
    {
      'rows' => available_models.each_with_index.map { |model, index| { 'id' => index + 1, 'name' => model } }
    }
  end

  context 'when searching for snipeit models' do
    let(:agent) { create(:agent) }
    let(:query) do
      <<~QUERY
        query autocompleteSearchSnipeitModels($input: AutocompleteSearchSnipeitModelsInput!)  {
          autocompleteSearchSnipeitModels(input: $input) {
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
      allow(Snipeit).to receive(:query).and_return(models_api_result)
      gql.execute(query, variables: variables)
    end

    context 'when snipeit integration is disabled' do
      let(:snipeit_integration_active) { false }

      it 'raises an error' do
        expect(gql.result.error_type).to eq(Exceptions::Forbidden)
      end
    end

    context 'without limit' do
      it 'returns all models the API sent' do
        expect(gql.result.data.length).to eq(available_models.length)
      end

      it 'asks the API with the default limit' do
        expect(Snipeit).to have_received(:query).with('models', { 'limit' => 10 })
      end
    end

    context 'with limit' do
      let(:limit) { 1 }

      it 'passes the limit on to the API' do
        expect(Snipeit).to have_received(:query).with('models', hash_including('limit' => limit))
      end
    end

    context 'with search' do
      let(:query_string) { 'ThinkPad' }

      it 'lets the API filter instead of filtering the fetched page in Ruby' do
        expect(Snipeit).to have_received(:query).with('models', hash_including('search' => 'ThinkPad'))
      end

      it 'maps the API rows to autocomplete entries' do
        expect(gql.result.data.first).to eq({ 'value' => '1', 'label' => 'MacBook Pro' })
      end
    end

    context 'with a wildcard search' do
      let(:query_string) { '*' }

      it 'sends no search term' do
        expect(Snipeit).to have_received(:query).with('models', { 'limit' => 10 })
      end
    end

    context 'with a selected category' do
      let(:variables) { { input: { query: query_string, limit: limit, categoryId: '3' } } }

      it 'restricts the models to that category' do
        expect(Snipeit).to have_received(:query).with('models', hash_including('category_id' => '3'))
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
