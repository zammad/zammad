
require 'test_helper'

class OverviewAssetsTest < ActiveSupport::TestCase
  test 'assets' do

    UserInfo.current_user_id = 1
    roles = Role.where(name: %w[Customer])

    user1 = User.create_or_update(
      login: 'assets_overview1@example.org',
      firstname: 'assets_overview1',
      lastname: 'assets_overview1',
      email: 'assets_overview1@example.org',
      password: 'some_pass',
      active: true,
      roles: roles,
    )
    user2 = User.create_or_update(
      login: 'assets_overview2@example.org',
      firstname: 'assets_overview2',
      lastname: 'assets_overview2',
      email: 'assets_overview2@example.org',
      password: 'some_pass',
      active: true,
      roles: roles,
    )
    user3 = User.create_or_update(
      login: 'assets_overview3@example.org',
      firstname: 'assets_overview3',
      lastname: 'assets_overview3',
      email: 'assets_overview3@example.org',
      password: 'some_pass',
      active: true,
      roles: roles,
    )
    user4 = User.create_or_update(
      login: 'assets_overview4@example.org',
      firstname: 'assets_overview4',
      lastname: 'assets_overview4',
      email: 'assets_overview4@example.org',
      password: 'some_pass',
      active: true,
      roles: roles,
    )
    user5 = User.create_or_update(
      login: 'assets_overview5@example.org',
      firstname: 'assets_overview5',
      lastname: 'assets_overview5',
      email: 'assets_overview5@example.org',
      password: 'some_pass',
      active: true,
      roles: roles,
    )

    ticket_state1 = Ticket::State.find_by(name: 'new')
    ticket_state2 = Ticket::State.find_by(name: 'open')
    overview_role = Role.find_by(name: 'Agent')
    overview = Overview.create_or_update(
      name: 'my asset test',
      link: 'my_asset_test',
      prio: 1000,
      role_ids: [overview_role.id],
      user_ids: [user4.id, user5.id],
      condition: {
        'ticket.state_id' => {
          operator: 'is',
          value: [ ticket_state1.id, ticket_state2.id ],
        },
        'ticket.owner_id' => {
          operator: 'is',
          pre_condition: 'specific',
          value: user1.id,
          value_completion: 'John Smith <john.smith@example.com>'
        },
      },
      order: {
        by: 'created_at',
        direction: 'ASC',
      },
      view: {
        d: %w[title customer group created_at],
        s: %w[title customer group created_at],
        m: %w[number title customer group created_at],
        view_mode_default: 's',
      },
    )
    assets = overview.assets({})
    assert(assets[:User][user1.id])
    assert_not(assets[:User][user2.id])
    assert_not(assets[:User][user3.id])
    assert(assets[:User][user4.id])
    assert(assets[:User][user5.id])
    assert(assets[:TicketState][ticket_state1.id])
    assert(assets[:TicketState][ticket_state2.id])

    overview = Overview.create_or_update(
      name: 'my asset test',
      link: 'my_asset_test',
      prio: 1000,
      role_ids: [overview_role.id],
      user_ids: [user4.id],
      condition: {
        'ticket.state_id' => {
          operator: 'is',
          value: ticket_state1.id,
        },
        'ticket.owner_id' => {
          operator: 'is',
          pre_condition: 'specific',
          value: [user1.id, user2.id],
        },
      },
      order: {
        by: 'created_at',
        direction: 'ASC',
      },
      view: {
        d: %w[title customer group created_at],
        s: %w[title customer group created_at],
        m: %w[number title customer group created_at],
        view_mode_default: 's',
      },
    )
    assets = overview.assets({})
    assert(assets[:User][user1.id])
    assert(assets[:User][user2.id])
    assert_not(assets[:User][user3.id])
    assert(assets[:User][user4.id])
    assert_not(assets[:User][user5.id])
    assert(assets[:TicketState][ticket_state1.id])
    assert_not(assets[:TicketState][ticket_state2.id])
    overview.destroy!
  end

end
