# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'test_helper'

class SessionBasicTest < ActiveSupport::TestCase

  test 'c session create / update' do

    # create users
    roles  = Role.where(name: %w[Agent])
    groups = Group.all

    agent1 = User.create_or_update(
      login:         'session-agent-1',
      firstname:     'Session',
      lastname:      'Agent 1',
      email:         'session-agent1@example.com',
      password:      'agentpw',
      active:        true,
      roles:         roles,
      groups:        groups,
      updated_by_id: 1,
      created_by_id: 1,
    )

    # create sessions
    client_id1 = '123456789'
    Sessions.create(client_id1, {}, { type: 'websocket' })

    # check if session exists
    assert(Sessions.session_exists?(client_id1), 'check if session exists')

    # check session data
    data = Sessions.get(client_id1)
    assert(data[:meta], 'check if meta exists')
    assert(data[:user], 'check if user exists')
    assert_nil(data[:user]['id'], 'check if user id is correct')

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
    Sessions.destroy(client_id1)

    # check if session exists
    assert_not(Sessions.session_exists?(client_id1), 'check if session exists')

  end

  test 'c activity stream' do

    # create users
    roles  = Role.where(name: %w[Agent Admin])
    groups = Group.all

    agent1 = User.create_or_update(
      login:         'activity-stream-agent-1',
      firstname:     'Session',
      lastname:      "activity stream #{rand(99_999)}",
      email:         'activity-stream-agent1@example.com',
      password:      'agentpw',
      active:        true,
      roles:         roles,
      groups:        groups,
      updated_by_id: 1,
      created_by_id: 1,
    )

    # create min. on activity record
    random_name = "Random:#{rand(9_999_999_999)}"
    Group.create_or_update(
      name:          random_name,
      updated_by_id: 1,
      created_by_id: 1,
    )

    as_client1 = Sessions::Backend::ActivityStream.new(agent1, {}, false, '123-1', 3)

    # get as stream
    result1 = as_client1.push
    assert(result1, 'check as agent1')
    travel 1.second

    # next check should be empty
    result1 = as_client1.push
    assert_not(result1, 'check as agent1 - recall')

    # next check should be empty
    travel 4.seconds
    result1 = as_client1.push
    assert_not(result1, 'check as agent1 - recall 2')

    agent1.update!(email: 'activity-stream-agent11@example.com')
    Ticket.create!(
      title:         '12323',
      group_id:      1,
      priority_id:   1,
      state_id:      1,
      customer_id:   1,
      updated_by_id: 1,
      created_by_id: 1,
    )

    travel 4.seconds

    # get as stream
    result1 = as_client1.push
    assert( result1, 'check as agent1 - recall 3')
    travel_back
  end

end
