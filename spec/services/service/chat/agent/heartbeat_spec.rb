# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::Chat::Agent::Heartbeat do
  subject(:service) { described_class.with_current_user(agent).execute }

  let(:agent) { create(:agent) }

  before do
    Setting.set('chat', true)
    allow(Chat).to receive(:broadcast_agent_state_update)
  end

  it 'requires a current user' do
    expect { described_class.execute }.to raise_error(%r{Current user is required})
  end

  context 'when the agent never switched availability' do
    it 'creates their agent row as unavailable' do
      expect { service }.to change { Chat::Agent.find_by(updated_by_id: agent.id)&.active }.from(nil).to(false)
    end
  end

  context 'when the agent is available' do
    let!(:record) { travel_to(1.minute.ago) { create(:'chat/agent', active: true, updated_by: agent, created_by: agent) } }

    it 'moves their timestamp' do
      expect { service }.to change { record.reload.updated_at }
    end

    it 'keeps them available' do
      expect { service }.not_to change { record.reload.active }.from(true)
    end

    it 'keeps a flag another path changed meanwhile' do
      Chat::Agent.state(agent.id, false)

      expect { service }.not_to change { record.reload.active }.from(false)
    end

    # A flag read first and written back would undo the toggle.
    it 'keeps a flag another path changes while it runs' do
      toggled    = false
      subscriber = ActiveSupport::Notifications.subscribe('sql.active_record') do |*, payload|
        next if toggled || payload[:sql].exclude?('chat_agents')

        toggled = true
        Chat::Agent.where(id: record.id).update_all(active: false)
      end

      service

      expect(record.reload.active).to be(false)
    ensure
      ActiveSupport::Notifications.unsubscribe(subscriber)
    end

    it 'tells nobody' do
      service

      expect(Chat).not_to have_received(:broadcast_agent_state_update)
    end

    it 'returns true' do
      expect(service).to be(true)
    end
  end
end
