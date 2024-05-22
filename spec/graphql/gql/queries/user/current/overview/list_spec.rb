# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Queries::User::Current::Overview::List, type: :graphql do
  let(:query) do
    <<~QUERY
      query userCurrentOverviewList {
        userCurrentOverviewList {
          id
          name
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

  context 'when authenticated', authenticated_as: :user do
    let(:user)       { create(:agent) }
    let(:overview_1) { create(:overview) }
    let(:overview_2) { create(:overview) }

    it 'returns overviews', aggregate_failures: true do
      allow_any_instance_of(Service::User::Overview::List)
        .to receive(:execute)
        .and_return([overview_1, overview_2])

      allow(Service::User::Overview::List).to receive(:new).and_call_original

      gql.execute(query)

      expect(gql.result.data)
        .to contain_exactly(
          include('id' => gql.id(overview_1)),
          include('id' => gql.id(overview_2)),
        )

      expect(Service::User::Overview::List).to have_received(:new).with(user)
    end
  end

  context 'when unauthenticated' do
    before do
      gql.execute(query)
    end

    it_behaves_like 'graphql responds with error if unauthenticated'
  end
end
