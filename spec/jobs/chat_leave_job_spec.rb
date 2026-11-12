# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe ChatLeaveJob, type: :job do
  let(:chat)            { create(:chat) }
  let(:agent)           { create(:agent) }
  let(:customer_client) { SecureRandom.uuid }
  let(:agent_client)    { SecureRandom.uuid }
  let(:participants)    { [customer_client] }
  let(:session)         { create(:'chat/session', chat:, state: 'running', user: agent, preferences: { participants: }) }

  def connect_customer
    Sessions.create(customer_client, {}, {})
  end

  def beat(time)
    create(:'chat/agent', updated_by: agent).update_columns(updated_at: time)
  end

  before do
    allow(Chat).to receive(:broadcast_agent_state_update)
  end

  after do
    [customer_client, agent_client].each { |client_id| Sessions.destroy(client_id) }
  end

  describe '#perform' do
    subject(:perform) { described_class.perform_now(session.id, customer_client, nil) }

    context 'when the customer is gone' do
      let(:participants) { [customer_client, agent_client] }

      before { Sessions.create(agent_client, { 'id' => agent.id }, {}) }

      it 'closes the session' do
        perform

        expect(session.reload.state).to eq('closed')
      end

      it 'tells the participants who are left' do
        perform

        expect(Sessions.queue(agent_client)).to include(
          { 'event' => 'chat_session_left', 'data' => include('session_id' => session.session_id) },
        )
      end

      it 'tells the agents of the topic, the agent of the session included' do
        perform

        expect(Chat).to have_received(:broadcast_agent_state_update).with([chat.id], agent_ids: [agent.id])
      end
    end

    context 'when the customer is back and the agent has no client but a fresh beat' do
      before do
        connect_customer
        beat(1.minute.ago)
      end

      it 'leaves the session open', :aggregate_failures do
        perform

        expect(session.reload.state).to eq('running')
        expect(Chat).not_to have_received(:broadcast_agent_state_update)
      end
    end

    context 'when the customer is back and the beat of the agent is stale' do
      before do
        connect_customer
        beat(3.minutes.ago)
      end

      it 'closes the session' do
        perform

        expect(session.reload.state).to eq('closed')
      end
    end

    context 'when the session does not exist any more' do
      it 'does nothing' do
        expect { described_class.perform_now(0, customer_client, nil) }.not_to raise_error
      end
    end
  end
end
