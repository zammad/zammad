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

  test 'c collections group' do
    require 'sessions/backend/collections/group.rb'

    # create users
    roles  = Role.where(name: ['Agent'])
    groups = Group.all

    agent1 = User.create_or_update(
      login:         'session-collection-agent-1',
      firstname:     'Session',
      lastname:      'Agent 1',
      email:         'session-collection-agent1@example.com',
      password:      'agentpw',
      active:        true,
      roles:         roles,
      groups:        groups,
      updated_by_id: 1,
      created_by_id: 1,
    )

    collection_client1 = Sessions::Backend::Collections::Group.new(agent1, {}, false, '123-1', 3)
    collection_client2 = Sessions::Backend::Collections::Group.new(agent1, {}, false, '234-2', 3)

    # get whole collections
    result1 = collection_client1.push
    assert(result1.present?, 'check collections')
    sleep 0.6
    result2 = collection_client2.push
    assert(result2.present?, 'check collections')
    assert_equal(result1, result2, 'check collections')

    # next check should be empty
    result1 = collection_client1.push
    assert_not(result1, 'check collections - recall')
    travel 1.second
    result2 = collection_client2.push
    assert_not(result2, 'check collections - recall')

    # change collection
    group = Group.first
    travel 4.seconds
    group.touch
    travel 4.seconds

    # get whole collections
    result1 = collection_client1.push
    assert(result1.present?, 'check collections - after touch')

    result2 = collection_client2.push
    assert(result2.present?, 'check collections - after touch')
    assert_equal(result1, result2, 'check collections')

    # check again after touch
    result1 = collection_client1.push
    assert_nil(result1, 'check collections - after touch - recall')
    result2 = collection_client2.push
    assert_nil(result2, 'check collections - after touch - recall')

    # change collection
    group = Group.create!(
      name:          "SomeGroup::#{rand(999_999)}",
      active:        true,
      created_by_id: 1,
      updated_by_id: 1,
    )
    travel 4.seconds

    # get whole collections
    result1 = collection_client1.push
    assert(result1.present?, 'check collections - after create')
    result2 = collection_client2.push
    assert(result2.present?, 'check collections - after create')
    assert_equal(result1, result2, 'check collections')

    # check again after create
    travel 4.seconds
    result1 = collection_client1.push
    assert_nil(result1, 'check collections - after create - recall')
    result2 = collection_client2.push
    assert_nil(result2, 'check collections - after create - recall')

    # change collection
    group.destroy
    travel 4.seconds

    # get whole collections
    result1 = collection_client1.push
    assert(result1.present?, 'check collections - after destroy')
    result2 = collection_client2.push
    assert(result2.present?, 'check collections - after destroy')
    assert_equal(result1, result2, 'check collections')

    # check again after destroy
    travel 4.seconds
    result1 = collection_client1.push
    assert_nil(result1, 'check collections - after destroy - recall')
    result2 = collection_client2.push
    assert_nil(result2, 'check collections - after destroy - recall')
    travel_back
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

  test 'c ticket_create' do

    # create users
    roles  = Role.where(name: %w[Agent Admin])
    groups = Group.all

    agent1 = User.create_or_update(
      login:         'ticket_create-agent-1',
      firstname:     'Session',
      lastname:      "ticket_create #{rand(99_999)}",
      email:         'ticket_create-agent1@example.com',
      password:      'agentpw',
      active:        true,
      roles:         roles,
      groups:        groups,
      updated_by_id: 1,
      created_by_id: 1,
    )

    ticket_create_client1 = Sessions::Backend::TicketCreate.new(agent1, {}, false, '123-1', 3)

    # get as stream
    result1 = ticket_create_client1.push
    assert(result1, 'check ticket_create')
    travel 1.second

    # next check should be empty
    result1 = ticket_create_client1.push
    assert_not(result1, 'check ticket_create - recall')

    # next check should be empty
    travel 1.second
    result1 = ticket_create_client1.push
    assert_not(result1, 'check ticket_create - recall 2')

    Group.create!(
      name:          "SomeTicketCreateGroup::#{rand(999_999)}",
      active:        true,
      updated_by_id: 1,
      created_by_id: 1,
    )
    groups = Group.all
    agent1.groups = groups
    agent1.save!

    travel 4.seconds

    # get as stream
    result1 = ticket_create_client1.push
    assert(result1, 'check ticket_create - recall 3')
    travel_back
  end

end
