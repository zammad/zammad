# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Subscriptions::User::Current::TaskbarItemStateUpdates, type: :graphql do
  let(:user)         { create(:agent) }
  let(:taskbar)      { create(:taskbar, user_id: user.id, app: 'desktop', key: 'key', state: {}) }
  let(:variables)    { { taskbarItemId: gql.id(taskbar) } }
  let(:mock_channel) { build_mock_channel }
  let(:subscription) do
    <<~QUERY
      subscription userCurrentTaskbarItemStateUpdates($taskbarItemId: ID!) {
        userCurrentTaskbarItemStateUpdates(taskbarItemId: $taskbarItemId) {
          stateChanged
        }
      }
    QUERY
  end

  context 'with not authenticated user' do
    it 'does not subscribe to taskbar item updates and returns an authorization error' do
      gql.execute(subscription, variables: variables, context: { channel: mock_channel })

      expect(gql.result.error_type).to eq(Exceptions::NotAuthorized)
    end
  end

  context 'with authenticated user', authenticated_as: :user do
    it 'subscribes to taskbar item updates' do
      gql.execute(subscription, variables: variables, context: { channel: mock_channel })

      expect(gql.result.data).not_to be_nil
    end

    context 'when different attributes are updated' do
      context 'with state' do
        it 'triggers' do
          gql.execute(subscription, variables: variables, context: { channel: mock_channel })

          taskbar.update!(state: { 'dummy' => 'data' })

          result = mock_channel.mock_broadcasted_messages.first[:result]['data']['userCurrentTaskbarItemStateUpdates']
          expect(result).to eq({ 'stateChanged' => true })
        end
      end

      context 'with params' do
        it 'does not trigger' do
          gql.execute(subscription, variables: variables, context: { channel: mock_channel })

          taskbar.update!(params: { 'dummy' => 'data' })

          expect(mock_channel.mock_broadcasted_messages).to be_empty
        end
      end
    end

    context 'with different target app' do
      before { taskbar.update!(app: 'mobile') }

      it 'does not trigger' do
        gql.execute(subscription, variables: variables, context: { channel: mock_channel })

        taskbar.update!(state: { 'dummy' => 'data' })

        expect(mock_channel.mock_broadcasted_messages).to be_empty
      end
    end

    context 'with different target user' do
      let(:another_user) { create(:agent) }

      before { taskbar.update!(user_id: another_user.id) }

      it 'does not subscribe to taskbar item updates and returns a forbidden error' do
        gql.execute(subscription, variables: variables, context: { channel: mock_channel })

        taskbar.update!(state: { 'dummy' => 'data' })

        expect(gql.result.error_type).to eq(Exceptions::Forbidden)
      end
    end
  end
end
