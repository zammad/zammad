# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Queries::User::Current::Device::List, type: :graphql do
  context 'when listing user (session) devices' do
    let(:agent) { create(:agent) }
    let(:query) do
      <<~QUERY
        query userCurrentDeviceList {
          userCurrentDeviceList {
            id
            userId
            name
            os
            browser
            location
            deviceDetails
            locationDetails
            fingerprint
            userAgent
            ip
            createdAt
            updatedAt
          }
        }
      QUERY
    end

    before do
      create(:user_device, user_id: agent.id)
      create(:user_device, user_id: agent.id, location_details: { city_name: 'Berlin' })
      create(:user_device, user_id: agent.id, location: 'unknown', location_details: { city_name: 'Paris' })
      create(:user_device, user_id: agent.id, location: 'unknown')
      gql.execute(query, variables: { fingerprint: 'dummy' })
    end

    context 'when user is not authenticated' do
      it 'returns an error' do
        expect(gql.result.error_message).to eq('Authentication required')
      end
    end

    context 'when user is authenticated, but has no permission', authenticated_as: :agent do
      let(:agent) { create(:agent, roles: []) }

      it 'returns an error' do
        expect(gql.result.error_type).to eq(Exceptions::Forbidden)
      end
    end

    context 'when user is authenticated', :aggregate_failures, authenticated_as: :agent do
      it 'returns a list of devices' do
        expect(gql.result.data.length).to eq(4)
        # Devices are ordered by updated_at, so the most recently created comes first.
        expect(gql.result.data.pluck('location'))
          .to eq(['unknown', 'Paris', 'some location, Berlin', 'some location'])
      end
    end
  end
end
