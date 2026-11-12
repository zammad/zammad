# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# The legacy counterpart is spec/lib/sessions/event/chat_transfer_spec.rb.
RSpec.describe Service::Chat::Session::Transfer do
  subject(:service) { described_class.with_current_user(agent).execute(session:, topic: sales) }

  let(:support)            { create(:chat, name: 'Support') }
  let(:sales)              { create(:chat, name: 'Sales') }
  let(:agent)              { create(:agent, preferences: { chat: { active: { support.id.to_s => 'on' } } }) }
  let(:customer)           { create(:customer) }
  let(:customer_client_id) { SecureRandom.uuid }
  let(:session_owner)      { agent }
  let(:session_state)      { 'running' }
  let(:session) do
    create(:'chat/session', chat: support, state: session_state, user: session_owner, preferences: { participants: [customer_client_id] })
  end

  # The queue also carries the collection updates for users created meanwhile.
  def chat_messages_to_customer
    Sessions.queue(customer_client_id).select { |message| message['event'].start_with?('chat_') }
  end

  before do
    Setting.set('chat', true)

    Sessions.create(customer_client_id, { 'id' => customer.id }, {})
    Sessions.queue(customer_client_id)

    allow(Chat).to receive(:broadcast_agent_state_update)
  end

  it 'requires a current user' do
    expect { described_class.execute(session:, topic: sales) }.to raise_error(%r{Current user is required})
  end

  it 'puts the session back into the queue of the other topic', :aggregate_failures do
    expect(service).to eq(session)
    expect(session.reload).to have_attributes(chat_id: sales.id, state: 'waiting')
  end

  # Parity with the legacy event: until someone accepts it, the session counts against the seats of its agent.
  it 'leaves the session with its agent' do
    expect { service }.not_to change { session.reload.user_id }.from(agent.id)
  end

  it 'tells the agents of both topics, the agent of the session included' do
    service

    expect(Chat).to have_received(:broadcast_agent_state_update).with([support.id, sales.id], agent_ids: [agent.id])
  end

  it 'tells the customer' do
    service

    expect(chat_messages_to_customer).to eq([
                                              {
                                                'event' => 'chat_session_notice',
                                                'data'  => {
                                                  'session_id' => session.session_id,
                                                  'message'    => 'Conversation is transferred into another chat. Please stay tuned.',
                                                },
                                              },
                                            ])
  end

  context 'with a session of another agent' do
    let(:session_owner) { create(:agent) }

    it 'is forbidden and leaves the session alone', :aggregate_failures do
      expect { service }.to raise_error(Exceptions::Forbidden, 'You are not running this chat session.')

      expect(session.reload).to have_attributes(chat_id: support.id, state: 'running', user_id: session_owner.id)
      expect(Chat).not_to have_received(:broadcast_agent_state_update)
    end
  end

  context 'with a session that is waiting for an agent' do
    let(:session_owner) { nil }
    let(:session_state) { 'waiting' }

    it 'is forbidden' do
      expect { service }.to raise_error(Exceptions::Forbidden, 'You are not running this chat session.')
    end
  end

  # A transfer leaves the agent on the session, but it is not theirs to move again.
  context 'with a session that was transferred before' do
    let(:session_state) { 'waiting' }

    it 'is forbidden' do
      expect { service }.to raise_error(Exceptions::Forbidden, 'You are not running this chat session.')
    end
  end

  context 'with a closed session' do
    let(:session_state) { 'closed' }

    it 'is forbidden' do
      expect { service }.to raise_error(Exceptions::Forbidden, 'You are not running this chat session.')
    end
  end

  # The mutation loads the session, then the customer or a job closes it before the service writes.
  context 'with a session closed after it was loaded' do
    before do
      session
      Chat::Session.where(id: session.id).update_all(state: 'closed')
    end

    it 'is forbidden and leaves the session closed', :aggregate_failures do
      expect { service }.to raise_error(Exceptions::Forbidden, 'You are not running this chat session.')

      expect(session.reload).to have_attributes(chat_id: support.id, state: 'closed')
      expect(Chat).not_to have_received(:broadcast_agent_state_update)
      expect(chat_messages_to_customer).to be_empty
    end
  end
end
