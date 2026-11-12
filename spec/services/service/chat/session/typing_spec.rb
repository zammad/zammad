# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# The legacy event is exercised in spec/graphql/gql/subscriptions/chat/session_updates_spec.rb.
RSpec.describe Service::Chat::Session::Typing do
  subject(:service) { described_class.with_current_user(agent).execute(session:) }

  let(:topic)              { create(:chat, name: 'Support') }
  let(:agent)              { create(:agent) }
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
  end

  it 'requires a current user' do
    expect { described_class.execute(session:) }.to raise_error(%r{Current user is required})
  end

  it 'shows the widget that the agent is typing, as the old interface does', :aggregate_failures do
    expect(service).to be(true)
    expect(chat_messages_to_customer).to eq([
                                              {
                                                'event' => 'chat_session_typing',
                                                'data'  => { 'session_id' => session.session_id, 'user_id' => agent.id },
                                              },
                                            ])
  end

  it 'stores nothing' do
    expect { service }.not_to change(Chat::Message, :count)
  end

  context 'with a session of another agent' do
    let(:session_owner) { create(:agent) }

    it 'is forbidden and tells nobody', :aggregate_failures do
      expect { service }.to raise_error(Exceptions::Forbidden, 'You are not running this chat session.')

      expect(chat_messages_to_customer).to be_empty
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
end
