# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Mutations::User::Current::CallerNotificationUpdate, type: :graphql do
  let(:user) { create(:agent) }

  let(:mutation) do
    <<~GQL
      mutation userCurrentCallerNotificationUpdate($enabled: Boolean!) {
        userCurrentCallerNotificationUpdate(enabled: $enabled) {
          success
          errors {
            message
            field
          }
        }
      }
    GQL
  end

  let(:enabled)   { true }
  let(:variables) { { enabled: } }

  def execute_graphql_query
    gql.execute(mutation, variables: variables)
  end

  context 'when user is not authenticated' do
    it 'returns an error' do
      expect(execute_graphql_query.error_message).to eq('Authentication required')
    end
  end

  context 'when user is authenticated', authenticated_as: :user do
    it 'switches the caller notification on' do
      expect { execute_graphql_query }.to change { user.reload.preferences['cti'] }.from(nil).to(true)
    end

    it 'responds with success' do
      expect(execute_graphql_query.data).to include('success' => true)
    end

    context 'when the caller notification is on' do
      let(:enabled) { false }
      let(:user)    { create(:agent, preferences: { cti: true }) }

      it 'switches it off' do
        expect { execute_graphql_query }.to change { user.reload.preferences['cti'] }.from(true).to(false)
      end
    end

    context 'without the cti.agent permission' do
      let(:user) { create(:user, roles: [create(:role, permission_names: 'ticket.agent')]) }

      it 'is forbidden' do
        expect(execute_graphql_query.error_type).to eq(Exceptions::Forbidden)
      end
    end
  end
end
