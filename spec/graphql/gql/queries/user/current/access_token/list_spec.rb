# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Queries::User::Current::AccessToken::List, type: :graphql do
  let(:query) do
    <<~QUERY
      query userCurrentAccessTokenList {
        userCurrentAccessTokenList {
          id
        }
      }
    QUERY
  end

  context 'when user is authenticated, but has no permission', authenticated_as: :agent do
    let(:agent) { create(:agent, roles: []) }

    before do
      gql.execute(query)
    end

    it_behaves_like 'graphql responds with error if unauthenticated'
  end

  context 'when authorized', authenticated_as: :user do
    let(:user)  { create(:agent) }
    let(:token) { create(:token, user: user) }

    it 'returns objects from the service' do
      allow_any_instance_of(Service::User::AccessToken::List)
        .to receive(:execute)
        .and_return([token])

      gql.execute(query)

      expect(gql.result.data).to match_array(include('id' => gql.id(token)))
    end

    context 'when user has insufficient permissions' do
      let(:user) { create(:customer) }

      it 'returns error' do
        gql.execute(query)

        expect(gql.result.error_message)
          .to include("Failed Gql::EntryPoints::Queries's authorization check")
      end
    end
  end

  context 'when unauthenticated' do
    before do
      gql.execute(query)
    end

    it_behaves_like 'graphql responds with error if unauthenticated'
  end
end
