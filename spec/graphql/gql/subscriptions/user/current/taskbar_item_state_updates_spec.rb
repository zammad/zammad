# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

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
          stateUpdateType
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
          expect(result).to eq({ 'stateUpdateType' => 'changed' })
        end
      end

      context 'when also selecting the updated taskbar item' do
        let(:subscription) do
          <<~QUERY
            subscription userCurrentTaskbarItemStateUpdates($taskbarItemId: ID!) {
              userCurrentTaskbarItemStateUpdates(taskbarItemId: $taskbarItemId) {
                stateUpdateType
                taskbarItem {
                  id
                }
              }
            }
          QUERY
        end

        it 'includes the taskbar item so consumers can apply the new state directly' do
          gql.execute(subscription, variables: variables, context: { channel: mock_channel })

          taskbar.update!(state: { 'dummy' => 'data' })

          result = mock_channel.mock_broadcasted_messages.first[:result]['data']['userCurrentTaskbarItemStateUpdates']
          expect(result).to eq(
            { 'stateUpdateType' => 'changed', 'taskbarItem' => { 'id' => gql.id(taskbar) } }
          )
        end
      end

      # An edit screen stores only what differs from the object, so a field the user cleared arrives
      #   as an explicit nil. The tab still holds a draft and must not be told to reset - which is
      #   what would restore the value it just cleared.
      context 'with a state that only clears a field' do
        it 'triggers with a changed update type' do
          gql.execute(subscription, variables: variables, context: { channel: mock_channel })

          taskbar.update!(state: { 'form_id' => SecureRandom.uuid, 'ticket' => { 'owner_id' => nil } })

          result = mock_channel.mock_broadcasted_messages.first[:result]['data']['userCurrentTaskbarItemStateUpdates']
          expect(result).to eq({ 'stateUpdateType' => 'changed' })
        end
      end

      context 'with a state that was emptied' do
        before { taskbar.update!(state: { 'ticket' => { 'title' => 'Draft title' } }) }

        it 'triggers with a reset update type' do
          gql.execute(subscription, variables: variables, context: { channel: mock_channel })

          taskbar.update!(state: {})

          result = mock_channel.mock_broadcasted_messages.first[:result]['data']['userCurrentTaskbarItemStateUpdates']
          expect(result).to eq({ 'stateUpdateType' => 'reset' })
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
