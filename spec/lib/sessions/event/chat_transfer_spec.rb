# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Sessions::Event::ChatTransfer do
  let(:client_id) { rand(123_456_789) }
  let(:chat) { Chat.first }
  let(:chat_transfer_into) { Chat.create!(name: 'chat 2', updated_by_id: 1, created_by_id: 1) }
  let(:chat_session) do
    Sessions.create('customer_session_id', { 'id' => customer.id }, {})
    Sessions.queue('customer_session_id')
    Chat::Session.create(
      chat_id:     chat.id,
      user_id:     nil,
      preferences: { participants: ['customer_session_id'] },
      state:       'running',
    )
  end
  let!(:agent) do
    create(:agent, preferences: { chat: { active: { chat.id.to_s => 'on' } } })
  end
  let!(:customer) { create(:customer) }
  let(:subject_as_agent) do
    Sessions.create(client_id, { 'id' => agent.id }, {})
    Sessions.queue(client_id)
    described_class.new(
      payload:   { 'data' => { 'session_id' => chat_session.session_id }, 'session_id' => chat_session.id, 'chat_id' => chat_transfer_into.id },
      user_id:   agent.id,
      client_id: client_id,
      clients:   {},
      session:   { 'id' => agent.id },
    )
  end

  before do
    Setting.set('chat', true)
  end

  context 'when transfering a chat session as customer' do
    let(:subject_as_customer) do
      Sessions.create(client_id, { 'id' => customer.id }, {})
      Sessions.queue(client_id)
      described_class.new(
        payload:   { 'data' => { 'session_id' => chat_session.session_id }, 'chat_id' => chat_transfer_into.id },
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

  context 'when transfering a chat session as agent' do
    it 'send out chat_session_notice to customer and agent and set chat session to waiting' do
      expect(subject_as_agent.run).to eq(nil)

      messages_to_customer = Sessions.queue('customer_session_id')
      expect(messages_to_customer.count).to eq(1)
      expect(messages_to_customer[0]).to eq(
        'event' => 'chat_session_notice',
        'data'  => {
          'message'    => 'Conversation transfered into other chat. Please stay tuned.',
          'session_id' => chat_session.session_id,
        },
      )

      messages_to_agent = Sessions.queue(client_id)
      expect(messages_to_agent.count).to eq(0)
    end
  end

end
