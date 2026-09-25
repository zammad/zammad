# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# Who is notified is decided by Cti::Log::TriggersSubscriptions and covered in spec/models/cti/log_spec.rb —
#   this covers the GraphQL surface only: the payload per event, the per-user scope and authorization.
RSpec.describe Gql::Subscriptions::Cti::LogUpdates, type: :graphql do
  let(:subscription) do
    <<~QUERY
      subscription ctiLogUpdates {
        ctiLogUpdates {
          addLog {
            id
            state
            from
            fromPretty
            done
          }
          updateLog {
            id
            state
            done
          }
          removeLogId
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
      expect(gql.result.data).to eq({ 'addLog' => nil, 'updateLog' => nil, 'removeLogId' => nil })
    end

    it 'receives a created call in the add field', :aggregate_failures do
      log = create(:cti_log, from: '4930609854180')

      data = mock_channel.mock_broadcasted_first.data
      expect(data).to include('updateLog' => nil, 'removeLogId' => nil)
      expect(data['addLog']).to include(
        'id'         => gql.id(log),
        'state'      => 'newCall',
        'from'       => '4930609854180',
        'fromPretty' => '+49 30 609854180',
        'done'       => false,
      )
    end

    it 'receives a state change in the update field' do
      log = create(:cti_log)
      mock_channel.mock_broadcasted_messages.clear

      log.update!(state: 'hangup', done: true)

      expect(mock_channel.mock_broadcasted_first.data).to eq(
        'addLog'      => nil,
        'updateLog'   => { 'id' => gql.id(log), 'state' => 'hangup', 'done' => true },
        'removeLogId' => nil,
      )
    end

    # Marking a call as handled changes nothing but the flag; other agents still have to see it.
    it 'receives a changed handled flag in the update field' do
      log = create(:cti_log, :not_reached)
      mock_channel.mock_broadcasted_messages.clear

      log.update!(done: true)

      expect(mock_channel.mock_broadcasted_first.data['updateLog']).to include(
        'id'   => gql.id(log),
        'done' => true,
      )
    end

    it 'receives a destroyed call as its id in the remove field' do
      log = create(:cti_log)
      mock_channel.mock_broadcasted_messages.clear

      log.destroy!

      expect(mock_channel.mock_broadcasted_first.data).to eq(
        'addLog'      => nil,
        'updateLog'   => nil,
        'removeLogId' => gql.id(log),
      )
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
