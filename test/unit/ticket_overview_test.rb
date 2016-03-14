# encoding: utf-8
require 'test_helper'

class TicketOverviewTest < ActiveSupport::TestCase

  # create base
  group = Group.create_or_update(
    name: 'OverviewTest',
    updated_at: '2015-02-05 16:37:00',
    updated_by_id: 1,
    created_by_id: 1,
  )
  roles  = Role.where(name: 'Agent')
  agent1 = User.create_or_update(
    login: 'ticket-overview-agent1@example.com',
    firstname: 'Overview',
    lastname: 'Agent1',
    email: 'ticket-overview-agent1@example.com',
    password: 'agentpw',
    active: true,
    roles: roles,
    groups: [group],
    updated_at: '2015-02-05 16:37:00',
    updated_by_id: 1,
    created_by_id: 1,
  )
  agent2 = User.create_or_update(
    login: 'ticket-overview-agent2@example.com',
    firstname: 'Overview',
    lastname: 'Agent2',
    email: 'ticket-overview-agent2@example.com',
    password: 'agentpw',
    active: true,
    roles: roles,
    #groups: groups,
    updated_at: '2015-02-05 16:38:00',
    updated_by_id: 1,
    created_by_id: 1,
  )
  roles = Role.where(name: 'Customer')
  organization1 = Organization.create_or_update(
    name: 'Overview Org',
    updated_at: '2015-02-05 16:37:00',
    updated_by_id: 1,
    created_by_id: 1,
  )
  customer1 = User.create_or_update(
    login: 'ticket-overview-customer1@example.com',
    firstname: 'Overview',
    lastname: 'Customer1',
    email: 'ticket-overview-customer1@example.com',
    password: 'customerpw',
    active: true,
    organization_id: organization1.id,
    roles: roles,
    updated_at: '2015-02-05 16:37:00',
    updated_by_id: 1,
    created_by_id: 1,
  )
  customer2 = User.create_or_update(
    login: 'ticket-overview-customer2@example.com',
    firstname: 'Overview',
    lastname: 'Customer2',
    email: 'ticket-overview-customer2@example.com',
    password: 'customerpw',
    active: true,
    organization_id: organization1.id,
    roles: roles,
    updated_at: '2015-02-05 16:37:00',
    updated_by_id: 1,
    created_by_id: 1,
  )
  customer3 = User.create_or_update(
    login: 'ticket-overview-customer3@example.com',
    firstname: 'Overview',
    lastname: 'Customer3',
    email: 'ticket-overview-customer3@example.com',
    password: 'customerpw',
    active: true,
    organization_id: nil,
    roles: roles,
    updated_at: '2015-02-05 16:37:00',
    updated_by_id: 1,
    created_by_id: 1,
  )
  Overview.destroy_all
  UserInfo.current_user_id = 1
  overview_role = Role.find_by(name: 'Agent')
  Overview.create_or_update(
    name: 'My assigned Tickets',
    link: 'my_assigned',
    prio: 1000,
    role_id: overview_role.id,
    condition: {
      'ticket.state_id' => {
        operator: 'is',
        value: [ 1, 2, 3, 7 ],
      },
      'ticket.owner_id' => {
        operator: 'is',
        pre_condition: 'current_user.id',
      },
    },
    order: {
      by: 'created_at',
      direction: 'ASC',
    },
    view: {
      d: %w(title customer group created_at),
      s: %w(title customer group created_at),
      m: %w(number title customer group created_at),
      view_mode_default: 's',
    },
  )

  Overview.create_or_update(
    name: 'Unassigned & Open',
    link: 'all_unassigned',
    prio: 1010,
    role_id: overview_role.id,
    condition: {
      'ticket.state_id' => {
        operator: 'is',
        value: [1, 2, 3],
      },
      'ticket.owner_id' => {
        operator: 'is',
        value: 1,
      },
    },
    order: {
      by: 'created_at',
      direction: 'ASC',
    },
    view: {
      d: %w(title customer group created_at),
      s: %w(title customer group created_at),
      m: %w(number title customer group created_at),
      view_mode_default: 's',
    },
  )
  Overview.create_or_update(
    name: 'My Tickets 2',
    link: 'my_tickets_2',
    prio: 1020,
    role_id: overview_role.id,
    user_ids: [agent2.id],
    condition: {
      'ticket.state_id' => {
        operator: 'is',
        value: [ 1, 2, 3, 7 ],
      },
      'ticket.owner_id' => {
        operator: 'is',
        pre_condition: 'current_user.id',
      },
    },
    order: {
      by: 'created_at',
      direction: 'ASC',
    },
    view: {
      d: %w(title customer group created_at),
      s: %w(title customer group created_at),
      m: %w(number title customer group created_at),
      view_mode_default: 's',
    },
  )

  overview_role = Role.find_by(name: 'Customer')
  Overview.create_or_update(
    name: 'My Tickets',
    link: 'my_tickets',
    prio: 1100,
    role_id: overview_role.id,
    condition: {
      'ticket.state_id' => {
        operator: 'is',
        value: [ 1, 2, 3, 4, 6, 7 ],
      },
      'ticket.customer_id' => {
        operator: 'is',
        pre_condition: 'current_user.id',
      },
    },
    order: {
      by: 'created_at',
      direction: 'DESC',
    },
    view: {
      d: %w(title customer state created_at),
      s: %w(number title state created_at),
      m: %w(number title state created_at),
      view_mode_default: 's',
    },
  )
  Overview.create_or_update(
    name: 'My Organization Tickets',
    link: 'my_organization_tickets',
    prio: 1200,
    role_id: overview_role.id,
    organization_shared: true,
    condition: {
      'ticket.state_id' => {
        operator: 'is',
        value: [ 1, 2, 3, 4, 6, 7 ],
      },
      'ticket.organization_id' => {
        operator: 'is',
        pre_condition: 'current_user.organization_id',
      },
    },
    order: {
      by: 'created_at',
      direction: 'DESC',
    },
    view: {
      d: %w(title customer state created_at),
      s: %w(number title customer state created_at),
      m: %w(number title customer state created_at),
      view_mode_default: 's',
    },
  )
  Overview.create_or_update(
    name: 'My Organization Tickets (open)',
    link: 'my_organization_tickets_open',
    prio: 1200,
    role_id: overview_role.id,
    user_ids: [customer2.id],
    organization_shared: true,
    condition: {
      'ticket.state_id' => {
        operator: 'is',
        value: [ 1, 2, 3 ],
      },
      'ticket.organization_id' => {
        operator: 'is',
        pre_condition: 'current_user.organization_id',
      },
    },
    order: {
      by: 'created_at',
      direction: 'DESC',
    },
    view: {
      d: %w(title customer state created_at),
      s: %w(number title customer state created_at),
      m: %w(number title customer state created_at),
      view_mode_default: 's',
    },
  )

  overview_role = Role.find_by(name: 'Admin')
  Overview.create_or_update(
    name: 'Not Shown Admin',
    link: 'not_shown_admin',
    prio: 9900,
    role_id: overview_role.id,
    condition: {
      'ticket.state_id' => {
        operator: 'is',
        value: [ 1, 2, 3 ],
      },
    },
    order: {
      by: 'created_at',
      direction: 'DESC',
    },
    view: {
      d: %w(title customer state created_at),
      s: %w(number title customer state created_at),
      m: %w(number title customer state created_at),
      view_mode_default: 's',
    },
  )

  test 'ticket create' do

    result = Ticket::Overviews.all(
      current_user: agent1,
    )
    assert_equal(2, result.count)
    assert_equal('My assigned Tickets', result[0].name)
    assert_equal('Unassigned & Open', result[1].name)

    result = Ticket::Overviews.all(
      current_user: agent2,
    )
    assert_equal(3, result.count)
    assert_equal('My assigned Tickets', result[0].name)
    assert_equal('Unassigned & Open', result[1].name)
    assert_equal('My Tickets 2', result[2].name)

    result = Ticket::Overviews.all(
      current_user: customer1,
    )
    assert_equal(2, result.count)
    assert_equal('My Tickets', result[0].name)
    assert_equal('My Organization Tickets', result[1].name)

    result = Ticket::Overviews.all(
      current_user: customer2,
    )
    assert_equal(3, result.count)
    assert_equal('My Tickets', result[0].name)
    assert_equal('My Organization Tickets', result[1].name)
    assert_equal('My Organization Tickets (open)', result[2].name)

    result = Ticket::Overviews.all(
      current_user: customer3,
    )
    assert_equal(1, result.count)
    assert_equal('My Tickets', result[0].name)

  end

end
