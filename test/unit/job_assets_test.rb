
require 'test_helper'

class JobAssetsTest < ActiveSupport::TestCase
  test 'assets' do

    UserInfo.current_user_id = 1
    roles = Role.where(name: %w[Customer])

    user1 = User.create_or_update(
      login: 'assets_job1@example.org',
      firstname: 'assets_job1',
      lastname: 'assets_job1',
      email: 'assets_job1@example.org',
      password: 'some_pass',
      active: true,
      roles: roles,
    )
    user2 = User.create_or_update(
      login: 'assets_job2@example.org',
      firstname: 'assets_job2',
      lastname: 'assets_job2',
      email: 'assets_job2@example.org',
      password: 'some_pass',
      active: true,
      roles: roles,
    )
    user3 = User.create_or_update(
      login: 'assets_job3@example.org',
      firstname: 'assets_job3',
      lastname: 'assets_job3',
      email: 'assets_job3@example.org',
      password: 'some_pass',
      active: true,
      roles: roles,
    )

    ticket_state1 = Ticket::State.find_by(name: 'new')
    ticket_state2 = Ticket::State.find_by(name: 'open')
    ticket_priority2 = Ticket::Priority.find_by(name: '2 normal')
    job = Job.create_or_update(
      name: 'my job',
      timeplan: {
        mon: true,
      },
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
      perform: {
        'ticket.priority_id' => {
          value: ticket_priority2.id,
        },
        'ticket.owner_id' => {
          pre_condition: 'specific',
          value: user2.id,
          value_completion: 'metest123@znuny.com <metest123@znuny.com>'
        },
      },
      disable_notification: true,
    )
    assets = job.assets({})
    assert(assets[:User][user1.id])
    assert(assets[:User][user2.id])
    assert_not(assets[:User][user3.id])
    assert(assets[:TicketState][ticket_state1.id])
    assert(assets[:TicketState][ticket_state2.id])
    assert(assets[:TicketPriority][ticket_priority2.id])

  end

end
