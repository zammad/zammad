# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Queries::AutocompleteSearch::IdoitObjectTypes, authenticated_as: :agent, type: :graphql do

  let(:available_types) { %w[Desk Computer Printer Screen Trashbin] }
  let(:types_api_result) do
    {
      'result' => available_types.each_with_index.map { |type, index| { 'id' => index, 'title' => type } }
    }
  end

  context 'when searching for idoit object types' do
    let(:agent) { create(:agent) }
    let(:query) do
      <<~QUERY
        query autocompleteSearchIdoitObjectTypes($input: AutocompleteSearchInput!)  {
          autocompleteSearchIdoitObjectTypes(input: $input) {
            value
            label
          }
        }
      QUERY
    end
    let(:variables)                { { input: { query: query_string, limit: limit } } }
    let(:query_string)             { '' }
    let(:limit)                    { nil }
    let(:idoit_integration_active) { true }

    before do
      Setting.set('idoit_integration', idoit_integration_active)
      allow(Idoit).to receive(:query).and_return(types_api_result)
      gql.execute(query, variables: variables)
    end

    context 'when idoit integration is disabled' do
      let(:idoit_integration_active) { false }

      it 'raises an error' do
        expect(gql.result.error_type).to eq(Exceptions::Forbidden)
      end
    end

    context 'without limit' do
      it 'finds all tags' do
        expect(gql.result.data.length).to eq(available_types.length)
      end
    end

    context 'with limit' do
      let(:limit) { 1 }

      it 'respects the limit' do
        expect(gql.result.data.length).to eq(limit)
      end
    end

    context 'with partial search' do
      let(:query_string) { 'I' }

      it 'has data' do
        expect(gql.result.data).to eq([{ 'value' => '2', 'label' => 'Printer' }, { 'value' => '4', 'label' => 'Trashbin' }])
      end
    end

    context 'with exact search' do
      let(:query_string) { 'Computer' }

      it 'has data' do
        expect(gql.result.data).to eq([{ 'value' => '1', 'label' => 'Computer' }])
      end
    end

    it_behaves_like 'graphql responds with error if unauthenticated'
  end
end
