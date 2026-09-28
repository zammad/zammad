# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Mutations::User::Current::NotificationPreferencesReset, :aggregate_failures, type: :graphql do
  let(:user) { create(:agent) }

  let(:mutation) do
    <<~GQL
      mutation userCurrentNotificationPreferencesReset {
        userCurrentNotificationPreferencesReset {
          user {
            personalSettings {
              notificationConfig {
                groupIds
              }
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
      it 'resets user preferences' do
        allow(User).to receive(:reset_personal_notifications_preferences!)

        execute_graphql_query

        expect(User).to have_received(:reset_personal_notifications_preferences!).with(user)
      end

      context 'with customized group limit and sound' do
        let(:user) do
          create(:agent).tap do |agent|
            agent.preferences['notification_config']['group_ids'] = [123]
            agent.preferences['notification_sound'] = { 'file' => 'Plop.mp3', 'enabled' => false }
            agent.save!
          end
        end

        it 'returns the cleared settings the form is rebuilt from' do
          execute_graphql_query

          expect(gql.result.data[:user][:personalSettings]).to include(
            'notificationConfig' => { 'groupIds' => nil },
            'notificationSound'  => nil
          )
        end
      end
    end
  end
end
