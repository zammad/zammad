# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Queries::AutocompleteSearch::SnipeitModels, authenticated_as: :agent, type: :graphql do

  let(:available_models) { %w[MacBook\ Pro ThinkPad UltraSharp DeskJet iPhone] }
  let(:models_api_result) do
    {
      'rows' => available_models.each_with_index.map { |model, index| { 'id' => index + 1, 'name' => model } }
    }
  end

  context 'when searching for snipeit models' do
    let(:agent) { create(:agent) }
    let(:query) do
      <<~QUERY
        query autocompleteSearchSnipeitModels($input: AutocompleteSearchInput!)  {
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
      it 'finds all models' do
        expect(gql.result.data.length).to eq(available_models.length)
      end
    end

    context 'with limit' do
      let(:limit) { 1 }

      it 'respects the limit' do
        expect(gql.result.data.length).to eq(limit)
      end
    end

    context 'with exact search' do
      let(:query_string) { 'ThinkPad' }

      it 'has data' do
        expect(gql.result.data).to eq([{ 'value' => '2', 'label' => 'ThinkPad' }])
      end
    end

    it_behaves_like 'graphql responds with error if unauthenticated'
  end
end
