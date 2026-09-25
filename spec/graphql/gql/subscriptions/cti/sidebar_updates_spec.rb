# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# Who is notified is decided by Cti::Log::TriggersSubscriptions and covered in spec/models/cti/log_spec.rb,
#   the payload's fields by spec/graphql/gql/queries/cti/sidebar_spec.rb — this covers the subscription
#   surface only: the pushed state, the per-user scope and authorization.
RSpec.describe Gql::Subscriptions::Cti::SidebarUpdates, type: :graphql do
  let(:subscription) do
    <<~QUERY
      subscription ctiSidebarUpdates {
        ctiSidebarUpdates {
          sidebar {
            unhandledCount
            ringingCalls {
              id
            }
          }
        }
      }
    QUERY
  end
  let(:mock_channel) { build_mock_channel }

  def configure_notify_map(notify_map)
    cti_config = Setting.get('cti_config')
    cti_config[:notify_map] = notify_map
    Setting.set('cti_config', cti_config)
  end

  before do
    gql.execute(subscription, context: { channel: mock_channel })
  end

  context 'with an agent', authenticated_as: :agent do
    let(:agent) { create(:agent) }

    it 'subscribes without an initial payload' do
      expect(gql.result.data).to eq({ 'sidebar' => nil })
    end

    it 'pushes the current state when a call comes in' do
      log = create(:cti_log, :inbound, :ringing)

      expect(mock_channel.mock_broadcasted_first.data['sidebar']).to eq(
        'unhandledCount' => 1,
        'ringingCalls'   => [{ 'id' => gql.id(log) }],
      )
    end

    it 'pushes the state again when the call changes' do
      log = create(:cti_log, :inbound, :ringing)
      mock_channel.mock_broadcasted_messages.clear

      log.update!(state: 'hangup', done: true)

      expect(mock_channel.mock_broadcasted_first.data['sidebar']).to eq('unhandledCount' => 0, 'ringingCalls' => [])
    end

    it 'pushes the state again when the call is destroyed' do
      log = create(:cti_log, :inbound, :ringing)
      mock_channel.mock_broadcasted_messages.clear

      log.destroy!

      expect(mock_channel.mock_broadcasted_first.data['sidebar']).to eq('unhandledCount' => 0, 'ringingCalls' => [])
    end

    context 'when a notify map places the call in another agent\'s queue' do
      before { configure_notify_map([{ queue: 'queue2', user_ids: [create(:agent).id.to_s] }]) }

      it 'receives nothing' do
        create(:cti_log, queue: 'queue2')

        expect(mock_channel.mock_broadcasted_messages).to be_empty
      end
    end
  end

  context 'with a user without the cti.agent permission', authenticated_as: :user do
    let(:user) { create(:user, roles: [create(:role, permission_names: 'ticket.agent')]) }

    it 'is forbidden' do
      expect(gql.result.error_type).to eq(Exceptions::Forbidden)
    end
  end

  it_behaves_like 'graphql responds with error if unauthenticated'
end
