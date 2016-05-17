# encoding: utf-8
require 'test_helper'

class SessionEnhancedTest < ActiveSupport::TestCase
  test 'a check clients and send messages' do

    # create users
    roles  = Role.where(name: ['Agent'])
    groups = Group.all

    UserInfo.current_user_id = 1
    agent1 = User.create_or_update(
      login: 'session-agent-1',
      firstname: 'Session',
      lastname: 'Agent 1',
      email: 'session-agent1@example.com',
      password: 'agentpw',
      active: true,
      roles: roles,
      groups: groups,
    )
    agent1.roles = roles
    agent1.save
    agent2 = User.create_or_update(
      login: 'session-agent-2',
      firstname: 'Session',
      lastname: 'Agent 2',
      email: 'session-agent2@example.com',
      password: 'agentpw',
      active: true,
      roles: roles,
      groups: groups,
    )
    agent2.roles = roles
    agent2.save
    agent3 = User.create_or_update(
      login: 'session-agent-3',
      firstname: 'Session',
      lastname: 'Agent 3',
      email: 'session-agent3@example.com',
      password: 'agentpw',
      active: true,
      roles: roles,
      groups: groups,
    )
    agent3.roles = roles
    agent3.save

    # create sessions
    client_id1 = '1234'
    client_id2 = '123456'
    client_id3 = 'abc'
    Sessions.destory(client_id1)
    Sessions.destory(client_id2)
    Sessions.destory(client_id3)
    Sessions.create(client_id1, agent1.attributes, { type: 'websocket' })
    Sessions.create(client_id2, agent2.attributes, { type: 'ajax' })
    Sessions.create(client_id3, agent3.attributes, { type: 'ajax' })

    # check if session exists
    assert(Sessions.session_exists?(client_id1), 'check if session exists')
    assert(Sessions.session_exists?(client_id2), 'check if session exists')
    assert(Sessions.session_exists?(client_id3), 'check if session exists')

    # check if session still exists after idle cleanup
    sleep 1
    Sessions.destory_idle_sessions(5)
    assert(Sessions.session_exists?(client_id1), 'check if session exists after 1 sec')
    assert(Sessions.session_exists?(client_id2), 'check if session exists after 1 sec')
    assert(Sessions.session_exists?(client_id3), 'check if session exists after 1 sec')

    # check if session still exists after idle cleanup with touched sessions
    sleep 6
    Sessions.touch(client_id1)
    Sessions.touch(client_id2)
    Sessions.touch(client_id3)
    Sessions.destory_idle_sessions(5)
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
    jobs = Thread.new {
      Sessions.jobs
    }
    sleep 5
    #jobs.join

    # check client threads
    assert(Sessions.thread_client_exists?(client_id1), 'check if client is running')
    assert(Sessions.thread_client_exists?(client_id2), 'check if client is running')
    assert(Sessions.thread_client_exists?(client_id3), 'check if client is running')

    # check if session still exists after idle cleanup
    sleep 8
    client_ids = Sessions.destory_idle_sessions(5)

    # check client sessions
    assert(!Sessions.session_exists?(client_id1), 'check if session is removed')
    assert(!Sessions.session_exists?(client_id2), 'check if session is removed')
    assert(!Sessions.session_exists?(client_id3), 'check if session is removed')

    sleep 10

    # check client threads
    assert(!Sessions.thread_client_exists?(client_id1), 'check if client is running')
    assert(!Sessions.thread_client_exists?(client_id2), 'check if client is running')
    assert(!Sessions.thread_client_exists?(client_id3), 'check if client is running')

    # exit jobs
    jobs.exit

  end

  test 'b check client and backends' do
    # create users
    roles        = Role.where(name: ['Agent'])
    groups       = Group.all
    organization = Organization.create(
      name: 'SomeOrg::' + rand(999_999).to_s, active: true,
      updated_by_id: 1,
      created_by_id: 1,
    )

    UserInfo.current_user_id = 1
    agent1 = User.create_or_update(
      login: 'session-agent-1',
      firstname: 'Session',
      lastname: 'Agent 1',
      email: 'session-agent1@example.com',
      password: 'agentpw',
      active: true,
      organization: organization,
      roles: roles,
      groups: groups,
    )
    agent1.roles = roles
    agent1.save
    agent2 = User.create_or_update(
      login: 'session-agent-2',
      firstname: 'Session',
      lastname: 'Agent 2',
      email: 'session-agent2@example.com',
      password: 'agentpw',
      active: true,
      organization: organization,
      roles: roles,
      groups: groups,
    )
    agent2.roles = roles
    agent2.save

    # create sessions
    client_id1_0 = '1234-1'
    client_id1_1 = '1234-2'
    client_id2   = '123456'
    Sessions.destory(client_id1_0)
    Sessions.destory(client_id1_1)
    Sessions.destory(client_id2)

    # start jobs
    jobs = Thread.new {
      Sessions.jobs
    }
    sleep 5
    Sessions.create(client_id1_0, agent1.attributes, { type: 'websocket' })
    sleep 6.5
    Sessions.create(client_id1_1, agent1.attributes, { type: 'websocket' })
    sleep 3.2
    Sessions.create(client_id2, agent2.attributes, { type: 'ajax' })

    # check if session exists
    assert(Sessions.session_exists?(client_id1_0), 'check if session exists')
    assert(Sessions.session_exists?(client_id1_1), 'check if session exists')
    assert(Sessions.session_exists?(client_id2), 'check if session exists')
    sleep 11

    # check collections
    collections = {
      'Group' => true,
      'User'  => nil,
    }
    check_if_collection_reset_message_exists(client_id1_0, collections, 'init')
    check_if_collection_reset_message_exists(client_id1_1, collections, 'init')
    check_if_collection_reset_message_exists(client_id2, collections, 'init')

    collections = {
      'Group' => nil,
      'User'  => nil,
    }
    check_if_collection_reset_message_exists(client_id1_0, collections, 'init2')
    check_if_collection_reset_message_exists(client_id1_1, collections, 'init2')
    check_if_collection_reset_message_exists(client_id2, collections, 'init2')

    sleep 11

    collections = {
      'Group' => nil,
      'User'  => nil,
    }
    check_if_collection_reset_message_exists(client_id1_0, collections, 'init3')
    check_if_collection_reset_message_exists(client_id1_1, collections, 'init3')
    check_if_collection_reset_message_exists(client_id2, collections, 'init3')

    # change collection
    group = Group.first
    group.touch

    sleep 11

    # check collections
    collections = {
      'Group' => true,
      'User'  => nil,
    }
    check_if_collection_reset_message_exists(client_id1_0, collections, 'update')
    check_if_collection_reset_message_exists(client_id1_1, collections, 'update')
    check_if_collection_reset_message_exists(client_id2, collections, 'update')

    # check if session still exists after idle cleanup
    sleep 6
    client_ids = Sessions.destory_idle_sessions(5)

    # check client sessions
    assert(!Sessions.session_exists?(client_id1_0), 'check if session is removed')
    assert(!Sessions.session_exists?(client_id1_1), 'check if session is removed')
    assert(!Sessions.session_exists?(client_id2), 'check if session is removed')

  end

  def check_if_collection_reset_message_exists(client_id, collections_orig, type)
    messages = Sessions.queue(client_id)
    #puts "cid: #{client_id}"
    #puts "m: #{messages.inspect}"
    collections_result = {}
    messages.each {|message|
      #puts ""
      #puts "message: #{message.inspect}"
      next if message['event'] != 'resetCollection'
      #puts "rc: "
      next if !message['data']

      message['data'].each {|key, _value|
        #puts "rc: #{key}"
        collections_result[key] = true
      }
    }
    #puts "c: #{collections_result.inspect}"
    collections_orig.each {|key, _value|
      assert_equal( collections_orig[key], collections_result[key], "collection message for #{key} #{type}-check (client_id #{client_id})" )
    }
  end
end
