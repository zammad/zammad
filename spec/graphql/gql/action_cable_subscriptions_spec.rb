# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::ActionCableSubscriptions, type: :graphql do
  let(:originating_tab) { build_mock_channel }
  let(:other_tab)       { build_mock_channel }

  def subscribe(channel, browser_tab_id, variables: {})
    gql.execute(subscription, variables:, context: { channel:, browser_tab_id: })
  end

  def trigger_from_originating_tab(skip_subscriptions:, &)
    Gql::SubscriptionOrigin.with(browser_tab_id: 'originating-tab', skip_subscriptions:, &)
  end

  context 'with a subscription evaluated for every subscriber', authenticated_as: :user do
    let(:user)    { create(:agent) }
    let(:taskbar) { create(:taskbar, user_id: user.id, app: 'desktop', key: 'key', state: {}) }
    let(:subscription) do
      <<~QUERY
        subscription userCurrentTaskbarItemStateUpdates($taskbarItemId: ID!) {
          userCurrentTaskbarItemStateUpdates(taskbarItemId: $taskbarItemId) {
            stateUpdateType
          }
        }
      QUERY
    end

    before do
      subscribe(originating_tab, 'originating-tab', variables: { taskbarItemId: gql.id(taskbar) })
      subscribe(other_tab, 'other-tab', variables: { taskbarItemId: gql.id(taskbar) })
    end

    context 'when the originating tab skips it' do
      before do
        trigger_from_originating_tab(skip_subscriptions: %w[userCurrentTaskbarItemStateUpdates]) do
          taskbar.update!(state: { 'dummy' => 'data' })
        end
      end

      it 'does not deliver the update to the originating tab' do
        expect(originating_tab.mock_broadcasted_messages).to be_empty
      end

      it 'delivers the update to other tabs' do
        expect(other_tab.mock_broadcasted_first.data).to eq({ 'stateUpdateType' => 'changed' })
      end
    end

    context 'when the originating tab skips another subscription' do
      before do
        trigger_from_originating_tab(skip_subscriptions: %w[ticketUpdates]) do
          taskbar.update!(state: { 'dummy' => 'data' })
        end
      end

      it 'delivers the update to all tabs' do
        expect([originating_tab, other_tab]).to all(have_attributes(mock_broadcasted_messages: be_one))
      end
    end

    context 'when the change has no originating tab' do
      before { taskbar.update!(state: { 'dummy' => 'data' }) }

      it 'delivers the update to all tabs' do
        expect([originating_tab, other_tab]).to all(have_attributes(mock_broadcasted_messages: be_one))
      end
    end

    context 'when the connection of a tab is no longer authorized' do
      before do
        originating_tab.connection = instance_double(ApplicationCable::Connection, still_authorized?: false)
        other_tab.connection       = instance_double(ApplicationCable::Connection, still_authorized?: true)

        taskbar.update!(state: { 'dummy' => 'data' })
      end

      it 'does not deliver the update to that tab' do
        expect(originating_tab.mock_broadcasted_messages).to be_empty
      end

      it 'delivers the update to the other tab' do
        expect(other_tab.mock_broadcasted_first.data).to eq({ 'stateUpdateType' => 'changed' })
      end
    end
  end

  context 'with a subscription evaluated once for all subscribers' do
    let(:subscription) do
      <<~QUERY
        subscription pushMessages {
          pushMessages {
            title
          }
        }
      QUERY
    end

    before do
      Gql::ZammadSchema.subscriptions = described_class.new(
        action_cable: ZammadSpecSupportGraphql::MockActionCable, action_cable_coder: ActiveSupport::JSON, schema: Gql::ZammadSchema,
        broadcast: true, default_broadcastable: false
      )

      subscribe(originating_tab, 'originating-tab')
      subscribe(other_tab, 'other-tab')

      trigger_from_originating_tab(skip_subscriptions: %w[pushMessages]) do
        Gql::Subscriptions::PushMessages.trigger({ title: 'Attention', text: 'Maintenance' })
      end
    end

    it 'does not deliver the update to the originating tab' do
      expect(originating_tab.mock_broadcasted_messages).to be_empty
    end

    it 'delivers the update to other tabs' do
      expect(other_tab.mock_broadcasted_first.data).to eq({ 'title' => 'Attention' })
    end
  end

  # A blocked connection is served as logged out, and public subscriptions reach a logged out
  #   client as well - the front end relies on configUpdates to log a blocked user out.
  context 'with a public subscription evaluated for every subscriber and a subscriber that is no longer authorized', authenticated_as: :agent do
    let(:agent) { create(:agent) }
    let(:subscription) do
      <<~QUERY
        subscription configUpdates {
          configUpdates {
            setting {
              key
              value
            }
          }
        }
      QUERY
    end

    before do
      originating_tab.connection = instance_double(ApplicationCable::Connection, still_authorized?: false)
      other_tab.connection       = instance_double(ApplicationCable::Connection, still_authorized?: true)

      subscribe(originating_tab, 'originating-tab')
      subscribe(other_tab, 'other-tab')

      Setting.set('maintenance_mode', true)
    end

    it 'delivers the update to every subscriber' do
      expect([originating_tab, other_tab]).to all(
        have_attributes(mock_broadcasted_first: have_attributes(data: { 'setting' => { 'key' => 'maintenance_mode', 'value' => true } }))
      )
    end

    # The payload of configUpdates depends on the authentication state, so the update for the
    #   unauthorized subscriber has to be computed as for a logged out client.
    context 'when the setting is only meant for authenticated clients' do
      let(:setting) do
        build(:setting, name: 'broadcast_test', state: 'authenticated only', frontend: true, preferences: { authentication: true })
      end

      before { setting.save }

      it 'does not deliver it to the unauthorized subscriber' do
        expect(originating_tab.mock_broadcasted_messages.map { |message| message.dig(:result, 'data', 'configUpdates', 'setting', 'key') }).not_to include('broadcast_test')
      end

      it 'delivers it to the authorized subscriber' do
        expect(other_tab.mock_broadcasted_messages.map { |message| message.dig(:result, 'data', 'configUpdates', 'setting', 'key') }).to include('broadcast_test')
      end
    end
  end

  context 'with a public subscription evaluated once and a subscriber that is no longer authorized' do
    let(:subscription) do
      <<~QUERY
        subscription pushMessages {
          pushMessages {
            title
          }
        }
      QUERY
    end

    before do
      Gql::ZammadSchema.subscriptions = described_class.new(
        action_cable: ZammadSpecSupportGraphql::MockActionCable, action_cable_coder: ActiveSupport::JSON, schema: Gql::ZammadSchema,
        broadcast: true, default_broadcastable: false
      )

      originating_tab.connection = instance_double(ApplicationCable::Connection, still_authorized?: false)
      other_tab.connection       = instance_double(ApplicationCable::Connection, still_authorized?: true)

      subscribe(originating_tab, 'originating-tab')
      subscribe(other_tab, 'other-tab')

      Gql::Subscriptions::PushMessages.trigger({ title: 'Attention', text: 'Maintenance' })
    end

    it 'delivers the update to every subscriber' do
      expect([originating_tab, other_tab]).to all(
        have_attributes(mock_broadcasted_first: have_attributes(data: { 'title' => 'Attention' }))
      )
    end
  end
end
