# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Mutations::User::Current::Overview::UpdateLastUsed, :aggregate_failures, type: :graphql do
  let(:mutation) do
    <<~MUTATION
      mutation userCurrentOverviewUpdateLastUsed($overviewsLastUsed: [UserCurrentOverviewLastUsed!]!) {
        userCurrentOverviewUpdateLastUsed(overviewsLastUsed: $overviewsLastUsed) {
          success
          errors {
            message
            field
          }
        }
      }
    MUTATION
  end

  let(:user)                   { create(:agent) }
  let(:overview1)              { Overview.find_by(link: 'my_assigned') }
  let(:overview2)              { Overview.find_by(link: 'all_unassigned') }
  let(:overviews_last_used) do
    [
      { overviewId: gql.id(overview1), lastUsedAt: '2024-07-16T19:23:00Z' },
      { overviewId: gql.id(overview2), lastUsedAt: '2023-07-16T19:23:00Z' },
    ]
  end
  let(:variables) { { overviewsLastUsed: overviews_last_used } }

  before do
    user.preferences[:overviews_last_used] = { Overview.find_by(link: 'my_subscribed_tickets') => '1999-07-16T19:23:00Z' }
    gql.execute(mutation, variables:)
  end

  context 'with authenticated user', authenticated_as: :user do
    it 'saves given information and overwrites previous data' do
      expect(user.reload.preferences[:overviews_last_used]).to eq(
        {
          overview1.id.to_s => '2024-07-16T19:23:00Z',
          overview2.id.to_s => '2023-07-16T19:23:00Z',
        }
      )
    end
  end

  context 'when unauthenticated' do
    it_behaves_like 'graphql responds with error if unauthenticated'
  end
end
