# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'test_helper'

class ChatTest < ActiveSupport::TestCase

  setup do
    groups = Group.all
    roles  = Role.where(name: %w[Agent])
    @agent1 = User.create!(
      login:         'ticket-chat-agent1@example.com',
      firstname:     'Notification',
      lastname:      'Agent1',
      email:         'ticket-chat-agent1@example.com',
      password:      'agentpw',
      active:        true,
      roles:         roles,
      groups:        groups,
      updated_at:    '2015-02-05 16:37:00',
      updated_by_id: 1,
      created_by_id: 1,
    )
    @agent2 = User.create!(
      login:         'ticket-chat-agent2@example.com',
      firstname:     'Notification',
      lastname:      'Agent2',
      email:         'ticket-chat-agent2@example.com',
      password:      'agentpw',
      active:        true,
      roles:         roles,
      groups:        groups,
      updated_at:    '2015-02-05 16:38:00',
      updated_by_id: 1,
      created_by_id: 1,
    )

    Chat.delete_all
    Chat::Session.delete_all
    Chat::Message.delete_all
    Chat::Agent.delete_all
    Setting.set('chat', false)
  end

  test 'instance_variable test' do
    assert_nil(Sessions::Event::Base.instance_variable_get(:@database_connection))
    assert_equal(Sessions::Event::ChatBase.instance_variable_get(:@database_connection), true)
    assert_equal(Sessions::Event::ChatStatusAgent.instance_variable_get(:@database_connection), true)
  end

  # check if db connection is available for chat events
  # see: https://github.com/zammad/zammad/issues/2353
  test 'chat event db connection test' do

    skip "Can't properly disconnect while Spring is in use." if defined?(Spring)

    class DummyWs # rubocop:disable Lint/ConstantDefinitionInBlock
      def send(msg)
        Rails.logger.info "WS send: #{msg}"
      end
    end

    # with websockets
    assert(User.first)

    # make sure to emulate unconnected WS env
    ActiveRecord::Base.remove_connection

    message = Sessions::Event.run(
      event:     'login',
      payload:   {},
      session:   123,
      remote_ip: '127.0.0.1',
      client_id: '123',
      clients:   {
        '123' => {
          websocket: DummyWs.new # to simulate a ws connection
        }
      },
      options:   {},
    )
    assert_equal(message, false)

    assert_raises(ActiveRecord::ConnectionNotEstablished) do
      User.first
    end

    message = Sessions::Event.run(
      event:     'chat_status_customer',
      payload:   {},
      session:   123,
      remote_ip: '127.0.0.1',
      client_id: '123',
      clients:   {
        '123' => DummyWs.new # to simulate a ws connection
      },
      options:   {},
    )
    assert_equal(message[:event], 'chat_error')

    assert_raises(ActiveRecord::ConnectionNotEstablished) do
      User.first
    end

    # re-establish connection
    ActiveRecord::Base.establish_connection

    # with ajax long polling
    assert(User.first)
    message = Sessions::Event.run(
      event:     'login',
      payload:   {},
      session:   123,
      remote_ip: '127.0.0.1',
      client_id: '123',
      clients:   {},
      options:   {},
    )
    assert_equal(message, false)
    assert(User.first)

    message = Sessions::Event.run(
      event:     'chat_status_customer',
      payload:   {},
      session:   123,
      remote_ip: '127.0.0.1',
      client_id: '123',
      clients:   {},
      options:   {},
    )
    assert_equal(message[:event], 'chat_error')
    assert(User.first)
  end

  test 'default test' do
    chat = Chat.create!(
      name:          'default',
      max_queue:     5,
      note:          '',
      active:        true,
      updated_by_id: 1,
      created_by_id: 1,
    )

    @agent1.preferences[:chat] = {
      active: {
        chat.id => 'on',
      },
    }
    @agent1.save!
    @agent2.preferences[:chat] = {
      active: {
        chat.id => 'on',
      },
    }
    @agent2.save!

    # check if feature is disabled
    assert_equal('chat_disabled', chat.customer_state[:state])
    assert_equal('chat_disabled', Chat.agent_state(@agent1.id)[:state])
    Setting.set('chat', true)

    # check customer state
    assert_equal('offline', chat.customer_state[:state])

    # check agent state
    agent_state = Chat.agent_state_with_sessions(@agent1.id)
    assert_equal(0, agent_state[:waiting_chat_count])
    assert_equal(0, agent_state[:running_chat_count])
    assert_equal([], agent_state[:active_sessions])
    assert_equal(0, agent_state[:seads_available])
    assert_equal(0, agent_state[:seads_total])
    assert_equal(false, agent_state[:active])

    # set agent 1 to active
    Chat::Agent.create_or_update(
      active:        true,
      concurrent:    4,
      updated_by_id: @agent1.id,
      created_by_id: @agent1.id,
    )

    # check customer state
    assert_equal('online', chat.customer_state[:state])

    # check agent state
    agent_state = Chat.agent_state_with_sessions(@agent1.id)
    assert_equal(0, agent_state[:waiting_chat_count])
    assert_equal(0, agent_state[:running_chat_count])
    assert_equal([], agent_state[:active_sessions])
    assert_equal(4, agent_state[:seads_available])
    assert_equal(4, agent_state[:seads_total])
    assert_equal(true, agent_state[:active])

    # start session
    chat_session1 = Chat::Session.create!(
      chat_id: chat.id,
      user_id: @agent1.id,
    )
    assert(chat_session1.session_id)

    # check customer state
    assert_equal('online', chat.customer_state[:state])

    # check agent state
    agent_state = Chat.agent_state_with_sessions(@agent1.id)
    assert_equal(1, agent_state[:waiting_chat_count])
    assert_equal(0, agent_state[:running_chat_count])
    assert_equal([], agent_state[:active_sessions])
    assert_equal(3, agent_state[:seads_available])
    assert_equal(4, agent_state[:seads_total])
    assert_equal(true, agent_state[:active])

    # activate second agent
    chat_agent2 = Chat::Agent.create!(
      active:        true,
      concurrent:    2,
      updated_by_id: @agent2.id,
      created_by_id: @agent2.id,
    )

    # check customer state
    assert_equal('online', chat.customer_state[:state])

    # check agent1 state
    agent_state = Chat.agent_state_with_sessions(@agent1.id)
    assert_equal(1, agent_state[:waiting_chat_count])
    assert_equal(0, agent_state[:running_chat_count])
    assert_equal([], agent_state[:active_sessions])
    assert_equal(5, agent_state[:seads_available])
    assert_equal(6, agent_state[:seads_total])
    assert_equal(true, agent_state[:active])

    # check agent2 state
    agent_state = Chat.agent_state_with_sessions(@agent2.id)
    assert_equal(1, agent_state[:waiting_chat_count])
    assert_equal(0, agent_state[:running_chat_count])
    assert_equal([], agent_state[:active_sessions])
    assert_equal(5, agent_state[:seads_available])
    assert_equal(6, agent_state[:seads_total])
    assert_equal(true, agent_state[:active])

    # start next chat
    Chat::Session.create(
      chat_id: chat.id,
    )

    # check customer state
    assert_equal('online', chat.customer_state[:state])

    # check agent1 state
    agent_state = Chat.agent_state_with_sessions(@agent1.id)
    assert_equal(2, agent_state[:waiting_chat_count])
    assert_equal(0, agent_state[:running_chat_count])
    assert_equal([], agent_state[:active_sessions])
    assert_equal(4, agent_state[:seads_available])
    assert_equal(6, agent_state[:seads_total])
    assert_equal(true, agent_state[:active])

    # check agent2 state
    agent_state = Chat.agent_state_with_sessions(@agent2.id)
    assert_equal(2, agent_state[:waiting_chat_count])
    assert_equal(0, agent_state[:running_chat_count])
    assert_equal([], agent_state[:active_sessions])
    assert_equal(4, agent_state[:seads_available])
    assert_equal(6, agent_state[:seads_total])
    assert_equal(true, agent_state[:active])

    # start new chats
    Chat::Session.create(
      chat_id: chat.id,
    )
    chat_session4 = Chat::Session.create!(
      chat_id: chat.id,
    )
    chat_session5 = Chat::Session.create!(
      chat_id: chat.id,
    )
    chat_session6 = Chat::Session.create!(
      chat_id: chat.id,
    )

    # check customer state
    assert_equal('no_seats_available', chat.customer_state[:state])

    # check agent1 state
    agent_state = Chat.agent_state_with_sessions(@agent1.id)
    assert_equal(6, agent_state[:waiting_chat_count])
    assert_equal(0, agent_state[:running_chat_count])
    assert_equal([], agent_state[:active_sessions])
    assert_equal(0, agent_state[:seads_available])
    assert_equal(6, agent_state[:seads_total])
    assert_equal(true, agent_state[:active])

    # check agent2 state
    agent_state = Chat.agent_state_with_sessions(@agent2.id)
    assert_equal(6, agent_state[:waiting_chat_count])
    assert_equal(0, agent_state[:running_chat_count])
    assert_equal([], agent_state[:active_sessions])
    assert_equal(0, agent_state[:seads_available])
    assert_equal(6, agent_state[:seads_total])
    assert_equal(true, agent_state[:active])

    chat_session6.user_id = @agent1.id
    chat_session6.state = 'running'
    chat_session6.save

    Chat::Message.create!(
      chat_session_id: chat_session6.id,
      content:         'message 1',
      created_by_id:   @agent1.id,
    )
    travel 1.second
    Chat::Message.create!(
      chat_session_id: chat_session6.id,
      content:         'message 2',
      created_by_id:   @agent1.id,
    )
    travel 1.second
    Chat::Message.create!(
      chat_session_id: chat_session6.id,
      content:         'message 3',
      created_by_id:   @agent1.id,
    )
    travel 1.second
    Chat::Message.create!(
      chat_session_id: chat_session6.id,
      content:         'message 4',
      created_by_id:   nil,
    )

    # check customer state
    customer_state = chat.customer_state
    assert_equal('no_seats_available', customer_state[:state])
    assert_equal(5, customer_state[:queue])

    # customer chat state
    customer_state = chat.customer_state(chat_session6.session_id)
    assert_equal('reconnect', customer_state[:state])
    assert(customer_state[:session])
    assert_equal(Array, customer_state[:session].class)
    assert_equal('message 1', customer_state[:session][0]['content'])
    assert_equal('message 2', customer_state[:session][1]['content'])
    assert_equal('message 3', customer_state[:session][2]['content'])
    assert_equal('message 4', customer_state[:session][3]['content'])
    assert_equal('Notification Agent1', customer_state[:agent][:name])
    assert_nil(customer_state[:agent][:avatar])

    # check agent1 state
    agent_state = Chat.agent_state_with_sessions(@agent1.id)
    assert_equal(5, agent_state[:waiting_chat_count])
    assert_equal(1, agent_state[:running_chat_count])
    assert_equal(Array, agent_state[:active_sessions].class)
    assert_equal(chat.id, agent_state[:active_sessions][0]['chat_id'])
    assert_equal(@agent1.id, agent_state[:active_sessions][0]['user_id'])
    assert(agent_state[:active_sessions][0]['messages'])
    assert_equal(Array, agent_state[:active_sessions][0]['messages'].class)
    assert_equal('message 1', agent_state[:active_sessions][0]['messages'][0]['content'])
    assert_equal('message 2', agent_state[:active_sessions][0]['messages'][1]['content'])
    assert_equal('message 3', agent_state[:active_sessions][0]['messages'][2]['content'])
    assert_equal('message 4', agent_state[:active_sessions][0]['messages'][3]['content'])
    assert_equal(0, agent_state[:seads_available])
    assert_equal(6, agent_state[:seads_total])
    assert_equal(true, agent_state[:active])

    # check agent2 state
    agent_state = Chat.agent_state_with_sessions(@agent2.id)
    assert_equal(5, agent_state[:waiting_chat_count])
    assert_equal(1, agent_state[:running_chat_count])
    assert_equal([], agent_state[:active_sessions])
    assert_equal(0, agent_state[:seads_available])
    assert_equal(6, agent_state[:seads_total])
    assert_equal(true, agent_state[:active])

    chat_agent2.active = false
    chat_agent2.save

    # check customer state
    assert_equal('no_seats_available', chat.customer_state[:state])
    assert_equal(5, chat.customer_state[:queue])

    # check agent1 state
    agent_state = Chat.agent_state_with_sessions(@agent1.id)
    assert_equal(5, agent_state[:waiting_chat_count])
    assert_equal(1, agent_state[:running_chat_count])
    assert_equal(Array, agent_state[:active_sessions].class)
    assert_equal(chat.id, agent_state[:active_sessions][0]['chat_id'])
    assert_equal(@agent1.id, agent_state[:active_sessions][0]['user_id'])
    assert(agent_state[:active_sessions][0]['messages'])
    assert_equal(Array, agent_state[:active_sessions][0]['messages'].class)
    assert_equal('message 1', agent_state[:active_sessions][0]['messages'][0]['content'])
    assert_equal('message 2', agent_state[:active_sessions][0]['messages'][1]['content'])
    assert_equal('message 3', agent_state[:active_sessions][0]['messages'][2]['content'])
    assert_equal('message 4', agent_state[:active_sessions][0]['messages'][3]['content'])
    assert_equal(-2, agent_state[:seads_available])
    assert_equal(4, agent_state[:seads_total])
    assert_equal(true, agent_state[:active])

    # check agent2 state
    agent_state = Chat.agent_state_with_sessions(@agent2.id)
    assert_equal(5, agent_state[:waiting_chat_count])
    assert_equal(1, agent_state[:running_chat_count])
    assert_equal([], agent_state[:active_sessions])
    assert_equal(-2, agent_state[:seads_available])
    assert_equal(4, agent_state[:seads_total])
    assert_equal(false, agent_state[:active])

    chat_session6.state = 'closed'
    chat_session6.save

    # check customer state
    assert_equal('no_seats_available', chat.customer_state[:state])
    assert_equal(5, chat.customer_state[:queue])

    # check agent1 state
    agent_state = Chat.agent_state_with_sessions(@agent1.id)
    assert_equal(5, agent_state[:waiting_chat_count])
    assert_equal(0, agent_state[:running_chat_count])
    assert_equal([], agent_state[:active_sessions])
    assert_equal(-1, agent_state[:seads_available])
    assert_equal(4, agent_state[:seads_total])
    assert_equal(true, agent_state[:active])

    # check agent2 state
    agent_state = Chat.agent_state_with_sessions(@agent2.id)
    assert_equal(5, agent_state[:waiting_chat_count])
    assert_equal(0, agent_state[:running_chat_count])
    assert_equal([], agent_state[:active_sessions])
    assert_equal(-1, agent_state[:seads_available])
    assert_equal(4, agent_state[:seads_total])
    assert_equal(false, agent_state[:active])

    chat_session5.destroy
    chat_session4.destroy

    # check customer state
    assert_equal('online', chat.customer_state[:state])

    # check agent1 state
    agent_state = Chat.agent_state_with_sessions(@agent1.id)
    assert_equal(3, agent_state[:waiting_chat_count])
    assert_equal(0, agent_state[:running_chat_count])
    assert_equal([], agent_state[:active_sessions])
    assert_equal(1, agent_state[:seads_available])
    assert_equal(4, agent_state[:seads_total])
    assert_equal(true, agent_state[:active])

    # check agent2 state
    agent_state = Chat.agent_state_with_sessions(@agent2.id)
    assert_equal(3, agent_state[:waiting_chat_count])
    assert_equal(0, agent_state[:running_chat_count])
    assert_equal([], agent_state[:active_sessions])
    assert_equal(1, agent_state[:seads_available])
    assert_equal(4, agent_state[:seads_total])
    assert_equal(false, agent_state[:active])
    travel_back
  end

  test 'check if agent_state_with_sessions works correctly with 2 chats' do
    chat1 = Chat.create!(
      name:          'topic 1',
      max_queue:     5,
      note:          '',
      active:        true,
      updated_by_id: 1,
      created_by_id: 1,
    )
    chat2 = Chat.create!(
      name:          'topic 2',
      max_queue:     5,
      note:          '',
      active:        true,
      updated_by_id: 1,
      created_by_id: 1,
    )
    @agent1.preferences[:chat] = {
      active: {
        chat1.id.to_s => 'on',
      },
    }
    @agent1.save!
    @agent2.preferences[:chat] = {
      active: {
        chat2.id.to_s => 'on',
      },
    }
    @agent2.save!

    Setting.set('chat', true)

    # check customer state
    assert_equal('offline', chat1.customer_state[:state])
    assert_equal('offline', chat2.customer_state[:state])

    # check agent state
    agent_state = Chat.agent_state_with_sessions(@agent1.id)
    assert_equal(0, agent_state[:waiting_chat_count])
    assert_equal(0, agent_state[:running_chat_count])
    assert_equal([], agent_state[:active_sessions])
    assert_equal(0, agent_state[:seads_available])
    assert_equal(0, agent_state[:seads_total])
    assert_equal(false, agent_state[:active])

    # set agent 1 to active
    Chat::Agent.create!(
      active:        true,
      concurrent:    4,
      updated_by_id: @agent1.id,
      created_by_id: @agent1.id,
    )

    # check customer state
    assert_equal('online', chat1.customer_state[:state])
    assert_equal('offline', chat2.customer_state[:state])

    # check agent state
    agent_state = Chat.agent_state_with_sessions(@agent2.id)
    assert_equal(0, agent_state[:waiting_chat_count])
    assert_equal(0, agent_state[:running_chat_count])
    assert_equal([], agent_state[:active_sessions])
    assert_equal(0, agent_state[:seads_available])
    assert_equal(0, agent_state[:seads_total])
    assert_equal(false, agent_state[:active])

    # set agent 2 to active
    Chat::Agent.create!(
      active:        true,
      concurrent:    2,
      updated_by_id: @agent2.id,
      created_by_id: @agent2.id,
    )

    # check customer state
    assert_equal('online', chat1.customer_state[:state])
    assert_equal('online', chat2.customer_state[:state])

    # start session
    chat_session1 = Chat::Session.create!(
      chat_id: chat1.id,
      user_id: @agent1.id,
    )
    assert(chat_session1.session_id)

    # check agent1 state
    agent_state = Chat.agent_state_with_sessions(@agent1.id)
    assert_equal(1, agent_state[:waiting_chat_count])
    assert_equal(0, agent_state[:running_chat_count])
    assert_equal([], agent_state[:active_sessions])
    assert_equal(3, agent_state[:seads_available])
    assert_equal(4, agent_state[:seads_total])
    assert_equal(true, agent_state[:active])

    # check agent2 state
    agent_state = Chat.agent_state_with_sessions(@agent2.id)
    assert_equal(0, agent_state[:waiting_chat_count])
    assert_equal(0, agent_state[:running_chat_count])
    assert_equal([], agent_state[:active_sessions])
    assert_equal(2, agent_state[:seads_available])
    assert_equal(2, agent_state[:seads_total])
    assert_equal(true, agent_state[:active])
  end

  test 'if agent_active_chat_ids works correctly' do
    chat1 = Chat.create!(
      name:          'topic 1',
      max_queue:     5,
      note:          '',
      active:        true,
      updated_by_id: 1,
      created_by_id: 1,
    )
    chat2 = Chat.create!(
      name:          'topic 2',
      max_queue:     5,
      note:          '',
      active:        true,
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert_equal([], Chat.agent_active_chat_ids(@agent1))
    assert_equal([], Chat.agent_active_chat_ids(@agent2))

    @agent1.preferences[:chat] = {
      active: {
        chat1.id.to_s => 'on',
      },
    }
    @agent1.save!
    @agent2.preferences[:chat] = {
      active: {
        chat2.id => 'on',
      },
    }
    @agent2.save!
    assert_equal([chat1.id], Chat.agent_active_chat_ids(@agent1))
    assert_equal([chat2.id], Chat.agent_active_chat_ids(@agent2))

    @agent2.preferences[:chat] = {
      active: {
        chat2.id => 'off',
      },
    }
    @agent2.save!
    assert_equal([chat1.id], Chat.agent_active_chat_ids(@agent1))
    assert_equal([], Chat.agent_active_chat_ids(@agent2))
  end

  test 'blocked ip test' do
    chat = Chat.create!(
      name:          'ip test',
      max_queue:     5,
      note:          '',
      block_ip:      '127.0.0.1;127.0.0.2;127.1.0.*',
      active:        true,
      updated_by_id: 1,
      created_by_id: 1,
    )

    assert_not(chat.blocked_ip?('128.0.0.1'))
    assert_not(chat.blocked_ip?('127.0.0.30'))
    assert(chat.blocked_ip?('127.0.0.1'))
    assert(chat.blocked_ip?('127.0.0.2'))
    assert(chat.blocked_ip?('127.1.0.1'))
    assert(chat.blocked_ip?('127.1.0.100'))
  end

  test 'blocked country test' do
    chat = Chat.create!(
      name:          'country test',
      max_queue:     5,
      note:          '',
      block_country: 'AU;CH',
      active:        true,
      updated_by_id: 1,
      created_by_id: 1,
    )

    assert_not(chat.blocked_country?('127.0.0.1'))
    assert(chat.blocked_country?('1.1.1.8'))
  end

end
