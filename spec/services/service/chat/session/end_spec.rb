# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# The legacy counterpart is spec/lib/sessions/event/chat_session_close_spec.rb.
RSpec.describe Service::Chat::Session::End do
  subject(:service) { described_class.with_current_user(agent).execute(session:) }

  let(:topic)              { create(:chat, name: 'Support') }
  let(:preferences)        { {} }
  let(:agent)              { create(:agent, firstname: 'Chat', lastname: 'Agent', preferences:) }
  let(:customer)           { create(:customer) }
  let(:customer_client_id) { SecureRandom.uuid }
  let(:session_owner)      { agent }
  let(:session_state)      { 'running' }
  let(:session) do
    create(:'chat/session', chat: topic, state: session_state, user: session_owner, preferences: { participants: [customer_client_id] })
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
    allow(Chat).to receive(:broadcast_customer_state_update)
  end

  it 'requires a current user' do
    expect { described_class.execute(session:) }.to raise_error(%r{Current user is required})
  end

  it 'closes the session and returns it', :aggregate_failures do
    expect(service).to eq(session)
    expect(session.reload.state).to eq('closed')
  end

  it 'tells the agents of the topic, the agent of the session included, and the other waiting customers', :aggregate_failures do
    service

    expect(Chat).to have_received(:broadcast_agent_state_update).with([topic.id], agent_ids: [agent.id])
    expect(Chat).to have_received(:broadcast_customer_state_update).with(topic.id)
  end

  it 'tells the widget who closed the conversation, as the old interface does' do
    service

    expect(chat_messages_to_customer).to eq([
                                              {
                                                'event' => 'chat_session_closed',
                                                'data'  => { 'session_id' => session.session_id, 'realname' => 'Chat Agent' },
                                              },
                                            ])
  end

  context 'with an alternative name' do
    let(:preferences) { { chat: { alternative_name: 'some name' } } }

    it 'carries the alternative name' do
      service

      expect(chat_messages_to_customer.first['data']['realname']).to eq('some name')
    end
  end

  context 'with a session of another agent' do
    let(:session_owner) { create(:agent) }

    it 'is forbidden and leaves the session alone', :aggregate_failures do
      expect { service }.to raise_error(Exceptions::Forbidden, 'You are not running this chat session.')

      expect(session.reload.state).to eq('running')
      expect(Chat).not_to have_received(:broadcast_agent_state_update)
    end
  end

  %w[waiting closed].each do |state|
    context "with a #{state} session" do
      let(:session_state) { state }

      it 'is forbidden' do
        expect { service }.to raise_error(Exceptions::Forbidden, 'You are not running this chat session.')
      end
    end
  end

  # The mutation loads the session, then a transfer and another agent's accept happen before the service writes.
  context 'with a session another agent took over after it was loaded' do
    let(:other_agent) { create(:agent) }

    before do
      session
      Chat::Session.where(id: session.id).update_all(user_id: other_agent.id)
    end

    it 'is forbidden and leaves the session to the other agent', :aggregate_failures do
      expect { service }.to raise_error(Exceptions::Forbidden, 'You are not running this chat session.')

      expect(session.reload).to have_attributes(state: 'running', user_id: other_agent.id)
      expect(Chat).not_to have_received(:broadcast_agent_state_update)
      expect(chat_messages_to_customer).to be_empty
    end
  end
end
