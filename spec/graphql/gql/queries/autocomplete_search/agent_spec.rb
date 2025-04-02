# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Queries::AutocompleteSearch::Agent, authenticated_as: :agent, type: :graphql do

  context 'when searching for agents' do
    let(:agent)     { create(:agent) }
    let(:agents)    { create_list(:agent, 3, lastname: 'AutocompleteSearch') }
    let(:customers) { create_list(:customer, 3, lastname: 'AutocompleteSearch') } # must not be found
    let(:query)     do
      <<~QUERY
        query autocompleteSearchAgent($input: AutocompleteSearchUserInput!)  {
          autocompleteSearchAgent(input: $input) {
            value
            label
            labelPlaceholder
            heading
            headingPlaceholder
            disabled
            icon
          }
        }
      QUERY
    end
    let(:variables)    { { input: { query: query_string, limit: limit, exceptInternalId: except } } }
    let(:query_string) { agents.last.lastname }
    let(:limit)        { nil }
    let(:except)       { nil }

    before do
      agents && customers
      gql.execute(query, variables: variables)
    end

    context 'without limit' do
      it 'finds all agents' do
        expect(gql.result.data.length).to eq(agents.length)
      end
    end

    context 'with limit' do
      let(:limit) { 1 }

      it 'respects the limit' do
        expect(gql.result.data.length).to eq(limit)
      end
    end

    context 'with exact search' do
      let(:first_user_payload) do
        {
          'value'              => agents.first.id,
          'label'              => agents.first.fullname,
          'labelPlaceholder'   => nil,
          'heading'            => nil,
          'headingPlaceholder' => nil,
          'icon'               => nil,
          'disabled'           => nil,
        }
      end
      let(:query_string) { agents.first.login }

      it 'has data' do
        expect(gql.result.data).to include(first_user_payload)
      end
    end

    context 'when sending an empty search string' do
      let(:query_string) { '   ' }

      it 'returns nothing' do
        expect(gql.result.data.length).to eq(0)
      end
    end

    context 'when a specific agent is excepted' do
      let(:except) { agents.first.id }

      let(:second_user_payload) do
        {
          'value'              => agents.second.id,
          'label'              => agents.second.fullname,
          'labelPlaceholder'   => nil,
          'heading'            => nil,
          'headingPlaceholder' => nil,
          'icon'               => nil,
          'disabled'           => nil,
        }
      end

      let(:third_user_payload) do
        {
          'value'              => agents.third.id,
          'label'              => agents.third.fullname,
          'labelPlaceholder'   => nil,
          'heading'            => nil,
          'headingPlaceholder' => nil,
          'icon'               => nil,
          'disabled'           => nil,
        }
      end

      it 'filters out provided agent' do
        expect(gql.result.data).to eq([third_user_payload, second_user_payload])
      end
    end

    it_behaves_like 'graphql responds with error if unauthenticated'
  end
end
