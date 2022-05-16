# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Queries::AutocompleteSearch::User, type: :graphql, authenticated_as: :agent do

  context 'when searching for users' do
    let(:agent) { create(:agent) }
    let(:users) { create_list(:agent, 3, lastname: 'AutocompleteSearch') }
    let(:query) { read_graphql_file('shared/graphql/queries/autocompleteSearch/user.graphql') }
    let(:variables) { { query: query_string, limit: limit } }
    let(:query_string) { users.last.lastname }
    let(:limit) { nil }

    before do
      graphql_execute(query, variables: variables)
    end

    context 'without limit' do
      it 'finds all users' do
        expect(graphql_response['data']['autocompleteSearchUser'].length).to eq(users.length)
      end
    end

    context 'with limit' do
      let(:limit) { 1 }

      it 'respects the limit' do
        expect(graphql_response['data']['autocompleteSearchUser'].length).to eq(limit)
      end
    end

    context 'with exact search' do
      let(:first_user_payload) do
        {
          'value'            => Gql::ZammadSchema.id_from_object(users.first),
          'label'            => users.first.fullname,
          'labelPlaceholder' => nil,
          'icon'             => nil,
          'disabled'         => nil,
        }
      end
      let(:query_string) { users.first.login }

      it 'has data' do
        expect(graphql_response['data']['autocompleteSearchUser']).to eq([first_user_payload])
      end
    end

    context 'when sending an empty search string' do
      let(:query_string) { '   ' }

      it 'returns nothing' do
        expect(graphql_response['data']['autocompleteSearchUser'].length).to eq(0)
      end

      it 'has no error' do
        expect(graphql_response['data']['errors']).to be_nil
      end
    end

    it_behaves_like 'graphql responds with error if unauthenticated'
  end
end
