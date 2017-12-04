
require 'test_helper'

class TriggerAssetsTest < ActiveSupport::TestCase
  test 'assets' do

    UserInfo.current_user_id = 1
    roles = Role.where(name: %w[Customer])

    user1 = User.create_or_update(
      login: 'assets_trigger1@example.org',
      firstname: 'assets_trigger1',
      lastname: 'assets_trigger1',
      email: 'assets_trigger1@example.org',
      password: 'some_pass',
      active: true,
      roles: roles,
    )
    user2 = User.create_or_update(
      login: 'assets_trigger2@example.org',
      firstname: 'assets_trigger2',
      lastname: 'assets_trigger2',
      email: 'assets_trigger2@example.org',
      password: 'some_pass',
      active: true,
      roles: roles,
    )
    user3 = User.create_or_update(
      login: 'assets_trigger3@example.org',
      firstname: 'assets_trigger3',
      lastname: 'assets_trigger3',
      email: 'assets_trigger3@example.org',
      password: 'some_pass',
      active: true,
      roles: roles,
    )
    group1 = Group.create_or_update(
      name: 'group1_trigger',
      active: true,
    )

    ticket_state1 = Ticket::State.find_by(name: 'new')
    ticket_state2 = Ticket::State.find_by(name: 'open')
    ticket_priority2 = Ticket::Priority.find_by(name: '2 normal')
    trigger = Trigger.create_or_update(
      name: 'my trigger',
      condition: {
        'ticket.state_id' => {
          operator: 'is',
          value: [ ticket_state1.id ],
        },
        'ticket.owner_id' => {
          operator: 'is',
          pre_condition: 'specific',
          value: user1.id,
          value_completion: 'John Smith <john.smith@example.com>'
        },
      },
      perform: {
        'ticket.group_id' => {
          value: group1.id.to_s,
        },
      },
      disable_notification: true,
    )
    assets = trigger.assets({})
    assert(assets[:User][user1.id])
    assert_not(assets[:User][user2.id])
    assert_not(assets[:User][user3.id])
    assert(assets[:TicketState][ticket_state1.id])
    assert_not(assets[:TicketState][ticket_state2.id])
    assert_not(assets[:TicketPriority])
    assert(assets[:Group][group1.id])

  end

end
