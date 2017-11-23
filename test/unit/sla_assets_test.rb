
require 'test_helper'

class SlaAssetsTest < ActiveSupport::TestCase
  test 'assets' do

    UserInfo.current_user_id = 1
    roles = Role.where(name: %w[Customer])

    user1 = User.create_or_update(
      login: 'assets_sla1@example.org',
      firstname: 'assets_sla1',
      lastname: 'assets_sla1',
      email: 'assets_sla1@example.org',
      password: 'some_pass',
      active: true,
      roles: roles,
    )
    user2 = User.create_or_update(
      login: 'assets_sla2@example.org',
      firstname: 'assets_sla2',
      lastname: 'assets_sla2',
      email: 'assets_sla2@example.org',
      password: 'some_pass',
      active: true,
      roles: roles,
    )

    calendar1 = Calendar.create_or_update(
      name: 'US 1',
      timezone: 'America/Los_Angeles',
      business_hours: {
        mon: { '09:00' => '17:00' },
        tue: { '09:00' => '17:00' },
        wed: { '09:00' => '17:00' },
        thu: { '09:00' => '17:00' },
        fri: { '09:00' => '17:00' }
      },
      default: true,
      ical_url: nil,
      updated_by_id: 1,
      created_by_id: 1,
    )
    ticket_state1 = Ticket::State.find_by(name: 'new')
    ticket_state2 = Ticket::State.find_by(name: 'open')
    sla = Sla.create_or_update(
      name: 'my asset test',
      calendar_id: calendar1.id,
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
    )
    assets = sla.assets({})
    assert(assets[:User][user1.id], 'check assets')
    assert_not(assets[:User][user2.id], 'check assets')
    assert(assets[:TicketState][ticket_state1.id], 'check assets')
    assert(assets[:TicketState][ticket_state2.id], 'check assets')
    assert(assets[:Calendar][calendar1.id], 'check assets')

  end

end
