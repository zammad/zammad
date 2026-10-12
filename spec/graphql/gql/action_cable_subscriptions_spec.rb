# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::ActionCableSubscriptions, type: :graphql do
  let(:unauthorized_tab) { build_mock_channel.tap { |c| c.connection = instance_double(ApplicationCable::Connection, still_authorized?: false) } }
  let(:authorized_tab)   { build_mock_channel.tap { |c| c.connection = instance_double(ApplicationCable::Connection, still_authorized?: true) } }

  def subscribe(channel, variables: {})
    gql.execute(subscription, variables:, context: { channel: })
  end

  context 'with a subscription evaluated for every subscriber and a subscriber that is no longer authorized', authenticated_as: :user do
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
      subscribe(unauthorized_tab, variables: { taskbarItemId: gql.id(taskbar) })
      subscribe(authorized_tab, variables: { taskbarItemId: gql.id(taskbar) })

      taskbar.update!(state: { 'dummy' => 'data' })
    end

    it 'does not deliver the update to that subscriber' do
      expect(unauthorized_tab.mock_broadcasted_messages).to be_empty
    end

    it 'delivers the update to the other subscriber' do
      expect(authorized_tab.mock_broadcasted_first.data).to eq({ 'stateUpdateType' => 'changed' })
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
      subscribe(unauthorized_tab)
      subscribe(authorized_tab)

      Setting.set('maintenance_mode', true)
    end

    it 'delivers the update to every subscriber' do
      expect([unauthorized_tab, authorized_tab]).to all(
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
        expect(unauthorized_tab.mock_broadcasted_messages.map { |message| message.dig(:result, 'data', 'configUpdates', 'setting', 'key') }).not_to include('broadcast_test')
      end

      it 'delivers it to the authorized subscriber' do
        expect(authorized_tab.mock_broadcasted_messages.map { |message| message.dig(:result, 'data', 'configUpdates', 'setting', 'key') }).to include('broadcast_test')
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

      subscribe(authorized_tab)
      subscribe(unauthorized_tab)
    end

    it 'delivers the update to every subscriber' do
      Gql::Subscriptions::PushMessages.trigger({ title: 'Attention', text: 'Maintenance' })

      expect([unauthorized_tab, authorized_tab]).to all(
        have_attributes(mock_broadcasted_first: have_attributes(data: { 'title' => 'Attention' }))
      )
    end

    # No subscription evaluated once requires authentication yet, so one is simulated: its update is
    #   computed for the first subscriber only and must not reach the others as is.
    context 'when the subscription requires authentication', authenticated_as: :agent do
      let(:agent) { create(:agent) }

      before do
        allow(Gql::Subscriptions::PushMessages).to receive(:require_authentication).and_return(true)

        Gql::Subscriptions::PushMessages.trigger({ title: 'Attention', text: 'Maintenance' })
      end

      it 'does not deliver the update to the unauthorized subscriber' do
        expect(unauthorized_tab.mock_broadcasted_messages).to be_empty
      end

      it 'delivers the update to the authorized subscriber' do
        expect(authorized_tab.mock_broadcasted_first.data).to eq({ 'title' => 'Attention' })
      end
    end
  end
end
