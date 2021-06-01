# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Sessions::Event::ChatSessionStart do
  let(:client_id) { rand(123_456_789) }
  let(:chat) { Chat.first }
  let(:chat_session) do
    Sessions.create('customer_session_id', { 'id' => customer.id }, {})
    Sessions.queue('customer_session_id')
    Chat::Session.create(
      chat_id:     chat.id,
      user_id:     nil,
      preferences: { participants: ['customer_session_id'] },
      state:       'waiting',
    )
  end
  let!(:agent) do
    agent = create(:agent, preferences: { chat: { active: { chat.id.to_s => 'on' } } })
    file = File.open('test/data/image/1000x1000.png', 'rb')
    contents = file.read
    avatar = Avatar.add(
      object:        'User',
      o_id:          agent.id,
      default:       true,
      resize:        {
        content:   contents,
        mime_type: 'image/jpg',
      },
      source:        'web',
      deletable:     true,
      updated_by_id: 1,
      created_by_id: 1,
    )
    Avatar.set_default('User', agent.id, avatar.id)
    agent.image = avatar.store_hash
    agent.save!
    agent
  end
  let!(:customer) { create(:customer) }
  let(:subject_as_agent) do
    Sessions.create(client_id, { 'id' => agent.id }, {})
    Sessions.queue(client_id)
    described_class.new(
      payload:   { 'data' => chat_session.session_id },
      user_id:   agent.id,
      client_id: client_id,
      clients:   {},
      session:   { 'id' => agent.id },
    )
  end
  let(:chat_message_history) do
    Chat::Message.create!(
      chat_session_id: chat_session.id,
      content:         'some message',
    )
  end

  before do
    Setting.set('chat', true)
  end

  context 'when starting a chat session as customer' do
    let(:subject_as_customer) do
      Sessions.create(client_id, { 'id' => customer.id }, {})
      Sessions.queue(client_id)
      described_class.new(
        payload:   { 'data' => chat_session.session_id },
        user_id:   customer.id,
        client_id: client_id,
        clients:   {},
        session:   { 'id' => customer.id },
      )
    end

    context 'without chat.agent permissions' do
      it 'send out no_permission event to user' do
        expect(subject_as_customer.run).to eq(nil)
        messages = Sessions.queue(client_id)
        expect(messages.count).to eq(1)
        expect(messages).to eq([
                                 { 'event' => 'chat_error',
                                   'data'  => {
                                     'state' => 'no_permission'
                                   } }
                               ])
      end
    end
  end

  context 'when starting a chat session with invalid chat_session_id' do
    let(:subject_with_invalid_session_id) do
      described_class.new(
        payload:   { 'data' => 'not_existing_chat_session_id' },
        user_id:   agent.id,
        client_id: client_id,
        clients:   {},
        session:   { 'id' => agent.id },
      )
    end

    it 'return failed message' do
      expect(subject_with_invalid_session_id.run).to eq(
        event: 'chat_session_start',
        data:  {
          state:   'failed',
          message: 'No session available.',
        },
      )
    end
  end

  context 'when starting a chat session as agent' do
    it 'send out chat_session_start to customer and agent' do
      expect(subject_as_agent.run).to eq(nil)

      messages_to_customer = Sessions.queue('customer_session_id')
      expect(messages_to_customer.count).to eq(1)
      expect(messages_to_customer[0]).to eq(
        'event' => 'chat_session_start',
        'data'  => {
          'state'      => 'ok',
          'agent'      => {
            'name'   => agent.fullname,
            'avatar' => 'http://zammad.example.com/api/v1/users/image/4cbd23059d5eb008f28a0f8bfbc723be',
          },
          'chat_id'    => chat.id,
          'session_id' => chat_session.session_id,
        },
      )

      messages_to_agent = Sessions.queue(client_id)
      expect(messages_to_agent.count).to eq(1)
      expect(messages_to_agent[0]).to include(
        'event' => 'chat_session_start',
        'data'  => hash_including(
          'session' => hash_including(
            'user_id'     => agent.id,
            'state'       => 'running',
            'preferences' => hash_including(
              'participants' => ['customer_session_id', client_id]
            ),
            'id'          => chat_session.id,
            'chat_id'     => chat_session.chat_id,
            'session_id'  => chat_session.session_id,
            'name'        => nil,
          )
        )
      )
    end
  end

  context 'when starting a chat session as agent with alternative_name and no avatar_state' do
    it 'send out chat_session_start to customer (with prepared agent information) and agent' do
      agent.preferences[:chat] ||= {}
      agent.preferences[:chat][:alternative_name] = 'some name'
      agent.preferences[:chat][:avatar_state] = 'disabled'
      agent.save!
      expect(subject_as_agent.run).to eq(nil)

      messages_to_customer = Sessions.queue('customer_session_id')
      expect(messages_to_customer.count).to eq(1)
      expect(messages_to_customer[0]).to eq(
        'event' => 'chat_session_start',
        'data'  => {
          'state'      => 'ok',
          'agent'      => {
            'name'   => 'some name',
            'avatar' => nil,
          },
          'chat_id'    => chat.id,
          'session_id' => chat_session.session_id,
        },
      )

      messages_to_agent = Sessions.queue(client_id)
      expect(messages_to_agent.count).to eq(1)
      expect(messages_to_agent[0]).to include(
        'event' => 'chat_session_start',
        'data'  => hash_including(
          'session' => hash_including(
            'user_id'     => agent.id,
            'state'       => 'running',
            'preferences' => hash_including(
              'participants' => ['customer_session_id', client_id]
            ),
            'id'          => chat_session.id,
            'chat_id'     => chat_session.chat_id,
            'session_id'  => chat_session.session_id,
            'name'        => nil,
          )
        )
      )
    end
  end

  context 'when starting a chat session as agent with transfered conversation' do
    it 'send out chat_session_start to customer and agent with already created messages' do
      chat_message_history
      expect(subject_as_agent.run).to eq(nil)
      messages_to_customer = Sessions.queue('customer_session_id')
      expect(messages_to_customer.count).to eq(0)

      messages_to_agent = Sessions.queue(client_id)
      expect(messages_to_agent.count).to eq(1)
      expect(messages_to_agent[0]).to include(
        'event' => 'chat_session_start',
        'data'  => hash_including(
          'session' => hash_including(
            'user_id'     => agent.id,
            'state'       => 'running',
            'preferences' => hash_including(
              'participants' => ['customer_session_id', client_id]
            ),
            'messages'    => array_including(
              hash_including(
                'content' => 'some message',
              ),
            ),
            'id'          => chat_session.id,
            'chat_id'     => chat_session.chat_id,
            'session_id'  => chat_session.session_id,
            'name'        => nil,
          )
        )
      )
    end
  end

end
