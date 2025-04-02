# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

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
      end
    end

    context 'with authenticated user having one device and multiple related session', authenticated_as: :agent do
      let(:agent) { create(:agent) }
      let(:device) { create(:user_device, user_id: agent.id) }

      it 'destroys the device and all the related session' do
        sessions = Faker::Number.within(range: 2..42) # rubocop:disable Zammad/FakerUnique
        create_list(:session, sessions,
                    data: {
                      'user_id'                 => agent.id,
                      'user_device_fingerprint' => device.fingerprint,
                      'persistent'              => true
                    })

        expect { execute_graphql_query }.to change(UserDevice, :count).by(-1).and change(Session, :count).by(-1 * sessions)
      end
    end

    context 'with authenticated user having multiple devices and multiple related session', authenticated_as: :agent do
      let(:agent)   { create(:agent) }
      let(:device)  { create(:user_device, user_id: agent.id) }

      let(:agents)  { create_list(:agent, Faker::Number.within(range: 2..42)) } # rubocop:disable Zammad/FakerUnique
      let(:devices) do
        agents.map do |agent|
          create(:user_device, user_id: agent.id)
        end
      end

      it 'destroys only the selected device and all the related session' do
        sessions = Faker::Number.within(range: 2..42) # rubocop:disable Zammad/FakerUnique
        create_list(:session, sessions,
                    data: {
                      'user_id'                 => agent.id,
                      'user_device_fingerprint' => device.fingerprint,
                      'persistent'              => true
                    })

        devices.each do |device|
          create_list(:session, Faker::Number.within(range: 2..42), # rubocop:disable Zammad/FakerUnique
                      data: {
                        'user_id'                 => device.user_id,
                        'user_device_fingerprint' => device.fingerprint,
                        'persistent'              => true
                      })
        end

        expect { execute_graphql_query }.to change(UserDevice, :count).by(-1).and change(Session, :count).by(-1 * sessions)
      end
    end

    context 'with multiple authenticated users having identical device (fingerprint) and multiple related session', authenticated_as: :agent do
      let(:agent)  { create(:agent) }
      let(:device) { create(:user_device, user_id: agent.id) }

      let(:agents)  { create_list(:agent, Faker::Number.within(range: 2..42)) } # rubocop:disable Zammad/FakerUnique
      let(:devices) do
        agents.map do |agent|
          create(:user_device, user_id: agent.id, fingerprint: device.fingerprint)
        end
      end

      it 'destroys only the selected device and all the related session' do
        sessions = Faker::Number.within(range: 2..42) # rubocop:disable Zammad/FakerUnique
        create_list(:session, sessions,
                    data: {
                      'user_id'                 => agent.id,
                      'user_device_fingerprint' => device.fingerprint,
                      'persistent'              => true
                    })

        devices.each do |device|
          create_list(:session, Faker::Number.within(range: 2..42), # rubocop:disable Zammad/FakerUnique
                      data: {
                        'user_id'                 => device.user_id,
                        'user_device_fingerprint' => device.fingerprint,
                        'persistent'              => true
                      })
        end

        expect { execute_graphql_query }.to change(UserDevice, :count).by(-1).and change(Session, :count).by(-1 * sessions)
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
  end
end
