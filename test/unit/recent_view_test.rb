# encoding: utf-8
require 'test_helper'

class RecentViewTest < ActiveSupport::TestCase

  test 'simple tests' do

    ticket1 = Ticket.create(
      title: 'RecentViewTest 1 some title äöüß',
      group: Group.lookup( name: 'Users'),
      customer_id: 2,
      state: Ticket::State.lookup( name: 'new' ),
      priority: Ticket::Priority.lookup( name: '2 normal' ),
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert(ticket1, 'ticket created')
    ticket2 = Ticket.create(
      title: 'RecentViewTest 2 some title äöüß',
      group: Group.lookup(name: 'Users'),
      customer_id: 2,
      state: Ticket::State.lookup(name: 'new'),
      priority: Ticket::Priority.lookup(name: '2 normal'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert(ticket2, 'ticket created')
    user1 = User.find(2)
    RecentView.user_log_destroy(user1)

    RecentView.log(ticket1.class.to_s, ticket1.id, user1)
    sleep 1
    RecentView.log(ticket2.class.to_s, ticket2.id, user1)
    sleep 1
    RecentView.log(ticket1.class.to_s, ticket1.id, user1)
    sleep 1
    RecentView.log(ticket1.class.to_s, ticket1.id, user1)

    list = RecentView.list(user1)
    assert(list[0]['o_id'], ticket1.id)
    assert(list[0]['object'], 'Ticket')

    assert(list[1]['o_id'], ticket1.id)
    assert(list[1]['object'], 'Ticket')

    assert(list[2]['o_id'], ticket2.id)
    assert(list[2]['object'], 'Ticket')

    assert(list[3]['o_id'], ticket1.id)
    assert(list[3]['object'], 'Ticket')

    ticket1.destroy
    ticket2.destroy

    list = RecentView.list(user1)
    assert(!list[0], 'check if recent view list is empty')
    travel_back
  end

  test 'existing tests' do
    user = User.find(2)

    # log entry of not existing object
    RecentView.user_log_destroy(user)
    RecentView.log('ObjectNotExisting', 1, user)

    # check if list is empty
    list = RecentView.list(user)
    assert(!list[0], 'check if recent view list is empty')

    # log entry of not existing record
    RecentView.user_log_destroy(user)
    RecentView.log('User', 99_999_999, user)

    # check if list is empty
    list = RecentView.list(user)
    assert(!list[0], 'check if recent view list is empty')

    # log entry of not existing model with permission check
    RecentView.user_log_destroy(user)
    RecentView.log('Overview', 99_999_999, user)

    # check if list is empty
    list = RecentView.list(user)
    assert(!list[0], 'check if recent view list is empty')
  end

  test 'permission tests' do
    customer = User.find(2)

    groups = Group.where(name: 'Users')
    roles  = Role.where(name: 'Agent')
    agent  = User.create_or_update(
      login: 'recent-viewed-agent@example.com',
      firstname: 'RecentViewed',
      lastname: 'Agent',
      email: 'recent-viewed-agent@example.com',
      password: 'agentpw',
      active: true,
      roles: roles,
      groups: groups,
      updated_by_id: 1,
      created_by_id: 1,
    )
    Group.create_if_not_exists(
      name: 'WithoutAccess',
      note: 'Test for not access check.',
      updated_by_id: 1,
      created_by_id: 1
    )

    # no access for customer
    ticket1 = Ticket.create(
      title: 'RecentViewTest 1 some title äöüß',
      group: Group.lookup(name: 'WithoutAccess'),
      customer_id: 1,
      state: Ticket::State.lookup(name: 'new'),
      priority: Ticket::Priority.lookup(name: '2 normal'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert(ticket1, 'ticket created')

    # log entry of not existing object
    RecentView.user_log_destroy(customer)
    RecentView.log(ticket1.class.to_s, ticket1.id, customer)

    # check if list is empty
    list = RecentView.list(customer)
    assert(!list[0], 'check if recent view list is empty')

    # log entry of not existing object
    RecentView.user_log_destroy(agent)
    RecentView.log(ticket1.class.to_s, ticket1.id, agent)

    # check if list is empty
    list = RecentView.list(agent)
    assert(!list[0], 'check if recent view list is empty')

    # access for customer via customer id
    ticket1 = Ticket.create(
      title: 'RecentViewTest 1 some title äöüß',
      group: Group.lookup(name: 'WithoutAccess'),
      customer_id: 2,
      state: Ticket::State.lookup(name: 'new'),
      priority: Ticket::Priority.lookup(name: '2 normal'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert(ticket1, 'ticket created')

    # log entry
    RecentView.user_log_destroy(customer)
    RecentView.log(ticket1.class.to_s, ticket1.id, customer)

    # check if list is empty
    list = RecentView.list(customer)
    assert(list[0]['o_id'], ticket1.id)
    assert(list[0]['object'], 'Ticket')
    assert(!list[1], 'check if recent view list is empty')

    # log entry
    organization = Organization.find(1)
    RecentView.user_log_destroy(customer)
    RecentView.log(organization.class.to_s, organization.id, customer)

    # check if list is empty
    list = RecentView.list(customer)
    assert(!list[0], 'check if recent view list is empty')

    # log entry
    organization = Organization.find(1)
    RecentView.user_log_destroy(agent)
    RecentView.log(organization.class.to_s, organization.id, agent)

    # check if list is empty
    list = RecentView.list(agent)
    assert(list[0]['o_id'], organization.id)
    assert(list[0]['object'], 'Organization')
    assert(!list[1], 'check if recent view list is empty')
  end

end
