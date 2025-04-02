# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Mutations::User::Current::NotificationPreferencesReset, :aggregate_failures, type: :graphql do
  let(:user) { create(:agent) }

  let(:mutation) do
    <<~GQL
      mutation userCurrentNotificationPreferencesReset {
        userCurrentNotificationPreferencesReset {
          user {
            personalSettings {
              notificationSound {
                enabled
                file
              }
            }
          }
        }
      }
    GQL
  end

  def execute_graphql_query
    gql.execute(mutation)
  end

  context 'when user is not authenticated' do
    it 'returns an error' do
      expect(execute_graphql_query.error_message).to eq('Authentication required')
    end
  end

  context 'when user is authenticated', authenticated_as: :user do
    context 'without sufficient permissions', authenticated_as: :user do
      let(:user) do
        create(:agent).tap do |user|
          user.roles.each { |role| role.permission_revoke('user_preferences') }
        end
      end

      it 'returns an error' do
        expect(execute_graphql_query.error_type).to eq(Exceptions::Forbidden)
      end
    end

    context 'with sufficient permissions' do
      before do
        allow(User).to receive(:reset_notifications_preferences!)
      end

      it 'resets user preferences' do
        execute_graphql_query
        expect(gql.result.data[:notificationSound]).to be_nil
        expect(User).to have_received(:reset_notifications_preferences!).with(user)
      end
    end
  end
end
