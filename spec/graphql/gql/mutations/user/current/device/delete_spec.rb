# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# What deleting a device does is covered by spec/services/service/user/device/delete_spec.rb —
#   this covers the GraphQL surface only: authorization, and the payload.
RSpec.describe Gql::Mutations::User::Current::Device::Delete, :aggregate_failures, type: :graphql do
  context 'when destroying user (session) device' do
    let(:mutation) do
      <<~MUTATION
        mutation userCurrentDeviceDelete($deviceId: ID!) {
          userCurrentDeviceDelete(deviceId: $deviceId) {
            success
            errors {
              message
            }
          }
        }
      MUTATION
    end

    let(:variables) { { deviceId: Gql::ZammadSchema.id_from_internal_id(UserDevice, device.id) } }

    def execute_graphql_query
      gql.execute(mutation, variables: variables)
    end

    context 'with authenticated user having one device and one related session', authenticated_as: :agent do
      let(:agent) { create(:agent) }
      let(:device) { create(:user_device, user_id: agent.id) }

      it 'destroys the device and the related session' do
        create(:session,
               data: {
                 'user_id'                 => agent.id,
                 'user_device_fingerprint' => device.fingerprint,
                 'persistent'              => true
               })

        expect { execute_graphql_query }.to change(UserDevice, :count).by(-1).and change(Session, :count).by(-1)
        expect(gql.result.data).to include('success' => true)
      end
    end

    context 'when device is not owned from current user', authenticated_as: :agent do
      let(:agent)       { create(:agent) }
      let(:agent_other) { create(:agent) }
      let(:device)      { create(:user_device, user_id: agent_other.id) }

      before do
        execute_graphql_query
      end

      it 'returns an error' do
        expect(gql.result.error_type).to eq(Exceptions::Forbidden)
      end
    end

    context 'when unauthenticated' do
      let(:device) { create(:user_device, user_id: create(:agent).id) }

      before { execute_graphql_query }

      it_behaves_like 'graphql responds with error if unauthenticated'
    end
  end
end
