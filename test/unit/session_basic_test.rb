# encoding: utf-8
require 'test_helper'

class SessionBasicTest < ActiveSupport::TestCase

  user = User.lookup(id: 1)
  roles = Role.where(name: %w(Agent Admin))
  user.roles = roles
  user.save

  test 'a cache' do
    Sessions::CacheIn.set('last_run_test', true, { expires_in: 1.second })
    result = Sessions::CacheIn.get('last_run_test')
    assert_equal(true, result, 'check 1')

    # should not be expired
    result = Sessions::CacheIn.expired('last_run_test')
    assert_equal(false, result, 'check 1 - expired')

    # should be expired
    sleep 2
    result = Sessions::CacheIn.expired('last_run_test')
    assert_equal(true, result, 'check 1 - expired')

    # renew expire
    result = Sessions::CacheIn.get('last_run_test', re_expire: true)
    assert_equal(true, result, 'check 1 - re_expire')

    # should not be expired
    result = Sessions::CacheIn.expired('last_run_test')
    assert_equal(false, result, 'check 1 - expired')

    # ignore expired
    sleep 2
    result = Sessions::CacheIn.get('last_run_test', ignore_expire: true)
    assert_equal(true, result, 'check 1 - ignore_expire')

    # should be expired
    result = Sessions::CacheIn.expired('last_run_test')
    assert_equal(true, result, 'check 2')

    result = Sessions::CacheIn.get('last_run_test')
    assert_equal(nil, result, 'check 2')

    # check delete cache
    Sessions::CacheIn.set('last_run_delete', true, { expires_in: 5.seconds })
    result = Sessions::CacheIn.get('last_run_delete')
    assert_equal(true, result, 'check 1')
    Sessions::CacheIn.delete('last_run_delete')
    result = Sessions::CacheIn.get('last_run_delete')
    assert_equal(nil, nil, 'check delete')
  end

  test 'c session create / update' do

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

    # create sessions
    client_id1 = '123456789'
    Sessions.create(client_id1, {}, { type: 'websocket' })

    # check if session exists
    assert(Sessions.session_exists?(client_id1), 'check if session exists')

    # check session data
    data = Sessions.get(client_id1)
    assert(data[:meta], 'check if meta exists')
    assert(data[:user], 'check if user exists')
    assert_equal(data[:user]['id'], nil, 'check if user id is correct')

    # recreate session
    Sessions.create(client_id1, agent1.attributes, { type: 'websocket' })

    # check if session exists
    assert(Sessions.session_exists?(client_id1), 'check if session exists')

    # check session data
    data = Sessions.get(client_id1)
    assert(data[:meta], 'check if meta exists')
    assert(data[:user], 'check if user exists')
    assert_equal(data[:user]['id'], agent1.id, 'check if user id is correct')

    # destroy session
    Sessions.destory(client_id1)

    # check if session exists
    assert(!Sessions.session_exists?(client_id1), 'check if session exists')

  end

  test 'c collections group' do
    require 'sessions/backend/collections/group.rb'

    UserInfo.current_user_id = 2
    user = User.lookup(id: 1)
    collection_client1 = Sessions::Backend::Collections::Group.new(user, {}, false, '123-1', 2)
    collection_client2 = Sessions::Backend::Collections::Group.new(user, {}, false, '234-2', 2)

    # get whole collections
    result1 = collection_client1.push
    assert(!result1.empty?, 'check collections')
    sleep 0.6
    result2 = collection_client2.push
    assert(!result2.empty?, 'check collections')
    assert_equal(result1, result2, 'check collections')

    # next check should be empty
    result1 = collection_client1.push
    assert(!result1, 'check collections - recall')
    sleep 1
    result2 = collection_client2.push
    assert(!result2, 'check collections - recall')

    # change collection
    group = Group.first
    group.touch
    sleep 3

    # get whole collections
    result1 = collection_client1.push
    assert(!result1.empty?, 'check collections - after touch')
    result2 = collection_client2.push
    assert(!result2.empty?, 'check collections - after touch')
    assert_equal(result1, result2, 'check collections')

    # check again after touch
    result1 = collection_client1.push
    assert(!result1, 'check collections - after touch - recall')
    result2 = collection_client2.push
    assert(!result2, 'check collections - after touch - recall')
    assert_equal(result1, result2, 'check collections')

    # change collection
    group = Group.create(name: 'SomeGroup::' + rand(999_999).to_s, active: true)
    sleep 3

    # get whole collections
    result1 = collection_client1.push
    assert(!result1.empty?, 'check collections - after create')
    result2 = collection_client2.push
    assert(!result2.empty?, 'check collections - after create')
    assert_equal(result1, result2, 'check collections')

    # check again after create
    sleep 3
    result1 = collection_client1.push
    assert(!result1, 'check collections - after create - recall')
    result2 = collection_client2.push
    assert(!result2, 'check collections - after create - recall')
    assert_equal(result1, result2, 'check collections')

    # change collection
    group.destroy
    sleep 3

    # get whole collections
    result1 = collection_client1.push
    assert(!result1.empty?, 'check collections - after destroy')
    result2 = collection_client2.push
    assert(!result2.empty?, 'check collections - after destroy')
    assert_equal(result1, result2, 'check collections')

    # check again after destroy
    sleep 3
    result1 = collection_client1.push
    assert(!result1, 'check collections - after destroy - recall')
    result2 = collection_client2.push
    assert(!result2, 'check collections - after destroy - recall')
    assert_equal(result1, result2, 'check collections')
  end

  test 'c rss' do
    user = User.lookup(id: 1)
    collection_client1 = Sessions::Backend::Rss.new(user, {}, false, '123-1')

    # get whole collections
    result1 = collection_client1.push
    #puts "RSS1: #{result1.inspect}"
    assert(!result1.empty?, 'check rss')
    sleep 0.5

    # next check should be empty
    result1 = collection_client1.push
    #puts "R1: #{result1.inspect}"
    assert(!result1, 'check rss - recall')
  end

  test 'c activity stream' do

    # create users
    roles  = Role.where(name: %w(Agent Admin))
    groups = Group.all

    UserInfo.current_user_id = 2
    agent1 = User.create_or_update(
      login: 'activity-stream-agent-1',
      firstname: 'Session',
      lastname: "activity stream #{rand(99_999)}",
      email: 'activity-stream-agent1@example.com',
      password: 'agentpw',
      active: true,
      roles: roles,
      groups: groups,
    )
    agent1.roles = roles
    assert(agent1.save, 'create/update agent1')

    as_client1 = Sessions::Backend::ActivityStream.new(agent1, {}, false, '123-1', 2)

    # get as stream
    result1 = as_client1.push
    assert(result1, 'check as agent1')
    sleep 1

    # next check should be empty
    result1 = as_client1.push
    assert(!result1, 'check as agent1 - recall')

    # next check should be empty
    sleep 3
    result1 = as_client1.push
    assert(!result1, 'check as agent1 - recall 2')

    agent1.update_attribute(:email, 'activity-stream-agent11@example.com')
    ticket = Ticket.create(title: '12323', group_id: 1, priority_id: 1, state_id: 1, customer_id: 1)

    sleep 3

    # get as stream
    result1 = as_client1.push
    assert( result1, 'check as agent1 - recall 3')
  end

  test 'c ticket_create' do

    UserInfo.current_user_id = 2
    user = User.lookup(id: 1)
    ticket_create_client1 = Sessions::Backend::TicketCreate.new(user, {}, false, '123-1', 2)

    # get as stream
    result1 = ticket_create_client1.push
    assert(result1, 'check ticket_create')
    sleep 0.6

    # next check should be empty
    result1 = ticket_create_client1.push
    assert(!result1, 'check ticket_create - recall')

    # next check should be empty
    sleep 0.6
    result1 = ticket_create_client1.push
    assert(!result1, 'check ticket_create - recall 2')

    Group.create(name: 'SomeTicketCreateGroup::' + rand(999_999).to_s, active: true)

    sleep 3

    # get as stream
    result1 = ticket_create_client1.push
    assert(result1, 'check ticket_create - recall 3')
  end

end
