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
end
