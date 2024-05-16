# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'User Overview sorting', authenticated_as: :user, type: :request do
  let(:user)             { create(:agent) }
  let(:overview)         { Overview.first }
  let(:overview_sorting) { create(:user_overview_sorting, overview:, user:) }

  describe 'GET /user_overview_sortings' do
    it 'returns overviews and overview sortings' do
      overview_sorting

      get '/api/v1/user_overview_sortings'

      expect(json_response)
        .to include(
          'overviews'         => include(include('id' => overview.id)),
          'overview_sortings' => include(include('id' => overview_sorting.id))
        )
    end
  end

  describe 'POST /user_overview_sortings_prio' do
    it 'calls sorting creation service', aggregate_failures: true do
      allow(Service::User::Overview::UpdateOrder)
        .to receive(:new)
        .and_call_original

      expect_any_instance_of(Service::User::Overview::UpdateOrder)
        .to receive(:execute)
        .and_call_original

      post '/api/v1/user_overview_sortings_prio',
           params: { prios: [[overview.id, 0]] }

      expect(Service::User::Overview::UpdateOrder)
        .to have_received(:new)

      expect(response).to have_http_status(:ok)
    end

    it 'triggers subscription' do
      allow(Gql::Subscriptions::User::Current::OverviewOrderingUpdates).to receive(:trigger_by)

      post '/api/v1/user_overview_sortings_prio',
           params: { prios: [[overview.id, 0]] }

      expect(Gql::Subscriptions::User::Current::OverviewOrderingUpdates)
        .to have_received(:trigger_by).with(user)
    end
  end

  describe 'DELETE /user_overview_sortings/:id' do
    it 'deletes given sorting' do
      expect { delete "/api/v1/user_overview_sortings/#{overview_sorting.id}" }
        .to change { User::OverviewSorting.exists? overview_sorting.id }
        .to false
    end

    it 'triggers subscription' do
      allow(Gql::Subscriptions::User::Current::OverviewOrderingUpdates).to receive(:trigger_by)

      delete "/api/v1/user_overview_sortings/#{overview_sorting.id}"

      expect(Gql::Subscriptions::User::Current::OverviewOrderingUpdates)
        .to have_received(:trigger_by).with(user)
    end
  end
end
