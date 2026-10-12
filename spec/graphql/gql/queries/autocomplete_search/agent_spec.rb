# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# The query inherits from Gql::Queries::AutocompleteSearch::User, whose arguments and payload are
#   covered in user_spec.rb — this covers only what it changes: agents are found, customers are not.
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
      it 'finds the agents but no customers' do
        expect(gql.result.data.pluck('value')).to match_array(agents.map(&:id))
      end
    end

    context 'with limit' do
      let(:limit) { 1 }

      it 'respects the limit' do
        expect(gql.result.data.length).to eq(limit)
      end
    end

    it_behaves_like 'graphql responds with error if unauthenticated'
  end
end
