# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'test_helper'

class SessionEnhancedTest < ActiveSupport::TestCase
  test 'check clients and send messages' do

    # create users
    roles  = Role.where(name: ['Agent'])
    groups = Group.all

    UserInfo.current_user_id = 1
    agent1 = User.create_or_update(
      login:     'session-agent-1',
      firstname: 'Session',
      lastname:  'Agent 1',
      email:     'session-agent1@example.com',
      password:  'agentpw',
      active:    true,
      roles:     roles,
      groups:    groups,
    )
    agent1.save!
    agent2 = User.create_or_update(
      login:     'session-agent-2',
      firstname: 'Session',
      lastname:  'Agent 2',
      email:     'session-agent2@example.com',
      password:  'agentpw',
      active:    true,
      roles:     roles,
      groups:    groups,
    )
    agent2.save!
    agent3 = User.create_or_update(
      login:     'session-agent-3',
      firstname: 'Session',
      lastname:  'Agent 3',
      email:     'session-agent3@example.com',
      password:  'agentpw',
      active:    true,
      roles:     roles,
      groups:    groups,
    )
    agent3.save!

    # create sessions
    client_id1 = 'a1234'
    client_id2 = 'a123456'
    client_id3 = 'aabc'
    Sessions.destroy(client_id1)
    Sessions.destroy(client_id2)
    Sessions.destroy(client_id3)
    Sessions.create(client_id1, agent1.attributes, { type: 'websocket' })
    Sessions.create(client_id2, agent2.attributes, { type: 'ajax' })
    Sessions.create(client_id3, agent3.attributes, { type: 'ajax' })

    # check if session exists
    assert(Sessions.session_exists?(client_id1), 'check if session exists')
    assert(Sessions.session_exists?(client_id2), 'check if session exists')
    assert(Sessions.session_exists?(client_id3), 'check if session exists')

    # check if session still exists after idle cleanup
    sleep 1
    Sessions.destroy_idle_sessions(3)
    assert(Sessions.session_exists?(client_id1), 'check if session exists after 1 sec')
    assert(Sessions.session_exists?(client_id2), 'check if session exists after 1 sec')
    assert(Sessions.session_exists?(client_id3), 'check if session exists after 1 sec')

    # check if session still exists after idle cleanup with touched sessions
    sleep 4
    Sessions.touch(client_id1)
    Sessions.touch(client_id2)
    Sessions.touch(client_id3)
    Sessions.destroy_idle_sessions(3)
    assert(Sessions.session_exists?(client_id1), 'check if session exists after touch')
    assert(Sessions.session_exists?(client_id2), 'check if session exists after touch')
    assert(Sessions.session_exists?(client_id3), 'check if session exists after touch')

    # check session data
    data = Sessions.get(client_id1)
    assert(data[:meta], 'check if meta exists')
    assert(data[:user], 'check if user exists')
    assert_equal(data[:user]['id'], agent1.id, 'check if user id is correct')

    data = Sessions.get(client_id2)
    assert(data[:meta], 'check if meta exists')
    assert(data[:user], 'check if user exists')
    assert_equal(data[:user]['id'], agent2.id, 'check if user id is correct')

    data = Sessions.get(client_id3)
    assert(data[:meta], 'check if meta exists')
    assert(data[:user], 'check if user exists')
    assert_equal(data[:user]['id'], agent3.id, 'check if user id is correct')

    # send data to one client
    Sessions.send(client_id1, { msg: 'äöüß123' })
    Sessions.send(client_id1, { msg: 'äöüß1234' })
    messages = Sessions.queue(client_id1)
    assert_equal(3, messages.count, 'messages count')
    assert_equal('ws:login', messages[0]['event'], 'messages 1')
    assert_equal(true, messages[0]['data']['success'], 'messages 1')
    assert_equal('äöüß123', messages[1]['msg'], 'messages 2')
    assert_equal('äöüß1234', messages[2]['msg'], 'messages 3')

    messages = Sessions.queue(client_id2)
    assert_equal(messages.count, 1, 'messages count')
    assert_equal('ws:login', messages[0]['event'], 'messages 1')
    assert_equal(true, messages[0]['data']['success'], 'messages 1')

    messages = Sessions.queue(client_id3)
    assert_equal(messages.count, 1, 'messages count')
    assert_equal('ws:login', messages[0]['event'], 'messages 1')
    assert_equal(true, messages[0]['data']['success'], 'messages 1')

    # broadcast to all clients
    Sessions.broadcast({ msg: 'ooo123123123123123123' })
    messages = Sessions.queue(client_id1)
    assert_equal(messages.count, 1, 'messages count')
    assert_equal('ooo123123123123123123', messages[0]['msg'], 'messages broadcast 1')

    messages = Sessions.queue(client_id2)
    assert_equal(messages.count, 1, 'messages count')
    assert_equal('ooo123123123123123123', messages[0]['msg'], 'messages broadcast 1')

    messages = Sessions.queue(client_id3)
    assert_equal(messages.count, 1, 'messages count')
    assert_equal('ooo123123123123123123', messages[0]['msg'], 'messages broadcast 1')

    # send dedicated message to user
    Sessions.send_to(agent1.id, { msg: 'ooo1231231231231231234' })
    messages = Sessions.queue(client_id1)
    assert_equal(messages.count, 1, 'messages count')
    assert_equal('ooo1231231231231231234', messages[0]['msg'], 'messages send 1')

    messages = Sessions.queue(client_id2)
    assert_equal(messages.count, 0, 'messages count')

    messages = Sessions.queue(client_id3)
    assert_equal(messages.count, 0, 'messages count')

    # start jobs
    jobs = Thread.new do
      Sessions.jobs
    end
    sleep 6

    # check client threads
    assert(Sessions.thread_client_exists?(client_id1), 'check if client is running')
    assert(Sessions.thread_client_exists?(client_id2), 'check if client is running')
    assert(Sessions.thread_client_exists?(client_id3), 'check if client is running')

    # check if session still exists after idle cleanup
    travel 10.seconds
    Sessions.destroy_idle_sessions(2)
    travel 2.seconds

    # check client sessions
    assert_not(Sessions.session_exists?(client_id1), 'check if session is removed')
    assert_not(Sessions.session_exists?(client_id2), 'check if session is removed')
    assert_not(Sessions.session_exists?(client_id3), 'check if session is removed')

    sleep 6

    # check client threads
    assert_not(Sessions.thread_client_exists?(client_id1), 'check if client is running')
    assert_not(Sessions.thread_client_exists?(client_id2), 'check if client is running')
    assert_not(Sessions.thread_client_exists?(client_id3), 'check if client is running')

    # exit jobs
    jobs.exit
    jobs.join
    travel_back
  end

  test 'check client and backends' do

    # create users
    roles        = Role.where(name: ['Agent'])
    groups       = Group.all
    organization = Organization.create(
      name: "SomeOrg::#{rand(999_999)}", active: true,
      updated_by_id: 1,
      created_by_id: 1,
    )

    UserInfo.current_user_id = 1
    agent1 = User.create_or_update(
      login:        'session-agent-1',
      firstname:    'Session',
      lastname:     'Agent 1',
      email:        'session-agent1@example.com',
      password:     'agentpw',
      active:       true,
      organization: organization,
      roles:        roles,
      groups:       groups,
    )
    agent1.save!
    agent2 = User.create_or_update(
      login:        'session-agent-2',
      firstname:    'Session',
      lastname:     'Agent 2',
      email:        'session-agent2@example.com',
      password:     'agentpw',
      active:       true,
      organization: organization,
      roles:        roles,
      groups:       groups,
    )
    agent2.save!
    agent3 = User.create_or_update(
      login:        'session-agent-3',
      firstname:    'Session',
      lastname:     'Agent 3',
      email:        'session-agent3@example.com',
      password:     'agentpw',
      active:       true,
      organization: organization,
      roles:        roles,
      groups:       groups,
    )
    agent3.save!

    # create sessions
    client_id1_0 = 'b1234-1'
    client_id1_1 = 'b1234-2'
    client_id2   = 'b123456'
    client_id3   = 'c123456'
    Sessions.destroy(client_id1_0)
    Sessions.destroy(client_id1_1)
    Sessions.destroy(client_id2)
    Sessions.destroy(client_id3)

    # start jobs
    jobs = Thread.new do
      Sessions.jobs
    end
    sleep 5
    Sessions.create(client_id1_0, agent1.attributes, { type: 'websocket' })
    sleep 6.5
    Sessions.create(client_id1_1, agent1.attributes, { type: 'websocket' })
    sleep 3.2
    Sessions.create(client_id2, agent2.attributes, { type: 'ajax' })
    sleep 3.2
    Sessions.create(client_id3, agent3.attributes, { type: 'websocket' })

    # check if session exists
    assert(Sessions.session_exists?(client_id1_0), 'check if session exists')
    assert(Sessions.session_exists?(client_id1_1), 'check if session exists')
    assert(Sessions.session_exists?(client_id2), 'check if session exists')
    assert(Sessions.session_exists?(client_id3), 'check if session exists')

    # check if session still exists after idle cleanup
    travel 10.seconds
    Sessions.destroy_idle_sessions(2)
    travel 2.seconds

    # check client sessions
    assert_not(Sessions.session_exists?(client_id1_0), 'check if session is removed')
    assert_not(Sessions.session_exists?(client_id1_1), 'check if session is removed')
    assert_not(Sessions.session_exists?(client_id2), 'check if session is removed')
    assert_not(Sessions.session_exists?(client_id3), 'check if session is removed')

    # exit jobs
    jobs.exit
    jobs.join
    travel_back
  end

end
