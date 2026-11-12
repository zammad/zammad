# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# The legacy event is exercised in spec/graphql/gql/subscriptions/chat/session_updates_spec.rb.
RSpec.describe Service::Chat::Session::MessageAdd do
  subject(:service) { described_class.with_current_user(agent).execute(session:, content:) }

  let(:topic)              { create(:chat, name: 'Support') }
  let(:agent)              { create(:agent) }
  let(:customer)           { create(:customer) }
  let(:customer_client_id) { SecureRandom.uuid }
  let(:session_owner)      { agent }
  let(:session_state)      { 'running' }
  let(:content)            { 'Hello, how can I help you?' }
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
    expect { described_class.execute(session:, content:) }.to raise_error(%r{Current user is required})
  end

  it 'stores the message with the agent as author', :aggregate_failures do
    expect(service).to be_a(Chat::Message).and have_attributes(chat_session_id: session.id, content: 'Hello, how can I help you?', created_by_id: agent.id)
    expect(session.messages.count).to eq(1)
  end

  context 'with content that is not safe' do
    let(:content) { '<b>Hello</b><script>alert(1)</script>' }

    it 'sanitizes it like any message' do
      expect(service.content).to eq('<b>Hello</b>')
    end
  end

  it 'hands the message to the widget as the old interface does', :aggregate_failures do
    message = service

    expect(chat_messages_to_customer).to match([
                                                 {
                                                   'event' => 'chat_session_message',
                                                   'data'  => {
                                                     'session_id' => session.session_id,
                                                     'message'    => hash_including('id' => message.id, 'content' => 'Hello, how can I help you?', 'created_by_id' => agent.id, 'chat_session_id' => session.id),
                                                   },
                                                 },
                                               ])
  end

  # The subscription of the agent loads the message from the database.
  it 'hands the message out only once the transaction it was written in is committed', :aggregate_failures do
    ActiveRecord::Base.transaction do
      service

      expect(chat_messages_to_customer).to be_empty
    end

    expect(chat_messages_to_customer.pluck('event')).to eq(['chat_session_message'])
  end

  context 'without content' do
    let(:content) { ' ' }

    it 'is refused and stores nothing', :aggregate_failures do
      expect { service }.to raise_error(Exceptions::UnprocessableContent, 'The message must not be empty.')

      expect(session.messages).to be_empty
      expect(chat_messages_to_customer).to be_empty
    end
  end

  context 'with a session of another agent' do
    let(:session_owner) { create(:agent) }

    it 'is forbidden and stores nothing', :aggregate_failures do
      expect { service }.to raise_error(Exceptions::Forbidden, 'You are not running this chat session.')

      expect(session.messages).to be_empty
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

  # The row changes behind the session the resolver loaded, as another request would.
  context 'with a session closed after it was loaded' do
    before do
      session
      Chat::Session.where(id: session.id).update_all(state: 'closed')
    end

    it 'is forbidden and neither stores nor delivers the message', :aggregate_failures do
      expect { service }.to raise_error(Exceptions::Forbidden, 'You are not running this chat session.')

      expect(Chat::Message.where(chat_session_id: session.id)).to be_empty
      expect(chat_messages_to_customer).to be_empty
    end
  end

  context 'with a session another agent took over after it was loaded' do
    before do
      session
      Chat::Session.where(id: session.id).update_all(user_id: create(:agent).id)
    end

    it 'is forbidden and neither stores nor delivers the message', :aggregate_failures do
      expect { service }.to raise_error(Exceptions::Forbidden, 'You are not running this chat session.')

      expect(Chat::Message.where(chat_session_id: session.id)).to be_empty
      expect(chat_messages_to_customer).to be_empty
    end
  end
end
