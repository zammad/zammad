# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Sessions::Event::ChatSessionClose do
  let(:client_id)          { SecureRandom.uuid }
  let(:customer_client_id) { SecureRandom.uuid }
  let(:chat)               { Chat.first }
  let(:agent)              { create(:agent, preferences: { chat: { active: { chat.id.to_s => 'on' } } }) }
  let(:customer)           { create(:customer) }
  let(:chat_session) do
    Chat::Session.create!(
      chat_id:     chat.id,
      user_id:     agent.id,
      preferences: { participants: [customer_client_id] },
      state:       'running',
    )
  end

  before do
    Setting.set('chat', true)

    Sessions.create(customer_client_id, { 'id' => customer.id }, {})
    Sessions.queue(customer_client_id)
    Sessions.create(client_id, { 'id' => customer.id }, {})
    Sessions.queue(client_id)

    allow(Chat).to receive(:broadcast_agent_state_update)
    allow(Chat).to receive(:broadcast_customer_state_update)
  end

  after do
    [client_id, customer_client_id].each { |id| Sessions.destroy(id) }
  end

  context 'when the customer closes a chat session of an agent' do
    subject(:event) do
      described_class.new(
        payload:   { 'data' => { 'session_id' => chat_session.session_id } },
        client_id: client_id,
        session:   { 'id' => customer.id },
      )
    end

    it 'closes the session' do
      event.run

      expect(chat_session.reload.state).to eq('closed')
    end

    # The session can sit in a topic the agent does not handle, they still have its window open.
    it 'tells the agents of the topic, the agent of the session included' do
      event.run

      expect(Chat).to have_received(:broadcast_agent_state_update).with([chat.id], agent_ids: [agent.id])
    end
  end
end
