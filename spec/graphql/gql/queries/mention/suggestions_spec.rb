# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Queries::Mention::Suggestions, type: :graphql do
  context 'when searching' do
    let(:agent)    { create(:agent, groups: [group]) }
    let(:customer) { create(:customer) }
    let(:group)    { create(:group) }

    let(:query) do
      <<~QUERY
        query mentionSuggestions($query: String!, $group: ID!) {
          mentionSuggestions(query: $query, group: $group) {
            id
            fullname
            email
          }
        }
      QUERY
    end

    let(:variables) { { query: search_query, group: Gql::ZammadSchema.id_from_object(group) } }

    before do
      gql.execute(query, variables: variables)
    end

    shared_examples 'returns the correct users' do
      it 'has data' do
        expect(gql.result.data).to include(expected_result)
      end
    end

    context 'with authenticated session', authenticated_as: :agent do
      let(:search_query) { agent.firstname[0..2] }

      let(:expected_result) do
        {
          'id'       => Gql::ZammadSchema.id_from_object(agent),
          'fullname' => agent.fullname,
          'email'    => agent.email,
        }
      end

      include_examples 'returns the correct users'

      context 'with no results' do
        let(:search_query) { 'foo' }

        it 'has no data' do
          expect(gql.result.data).to be_empty
        end
      end

      context 'with an agent that has no email' do
        let(:agent) { create(:agent, groups: [group], email: nil) }

        include_examples 'returns the correct users'
      end

      context 'with an agent that has no firstname/lastname' do
        let(:agent)        { create(:agent, groups: [group], firstname: nil, lastname: nil, email: 'foo@zammad.com') }
        let(:search_query) { 'foo' }

        include_examples 'returns the correct users'
      end
    end

    context 'with a customer', authenticated_as: :customer do
      let(:search_query) { agent.firstname[0..2] }

      it_behaves_like 'graphql responds with error if unauthenticated'
    end
  end
end
