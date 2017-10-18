# encoding: utf-8
require 'test_helper'

class SessionBasicTicketTest < ActiveSupport::TestCase

  setup do
    UserInfo.current_user_id = 1
    roles  = Role.where(name: ['Agent'])
    groups = Group.all

    @agent1 = User.create_or_update(
      login: 'session-basic-ticket-agent-1',
      firstname: 'Session',
      lastname: 'session basic ' + rand(99_999).to_s,
      email: 'session-basic-ticket-agent-1@example.com',
      password: 'agentpw',
      active: true,
      roles: roles,
      groups: groups,
    )

    @agent2 = User.create_or_update(
      login: 'session-basic-ticket-agent-2',
      firstname: 'Session',
      lastname: 'session basic ' + rand(99_999).to_s,
      email: 'session-basic-ticket-agent-2@example.com',
      password: 'agentpw',
      active: true,
      roles: roles,
      groups: groups,
    )
    Overview.destroy_all
    load "#{Rails.root}/db/seeds/overviews.rb"
  end

  test 'asset needed' do

    client1 = Sessions::Backend::TicketOverviewList.new(@agent1, {}, false, '123-1', 2)
    client2 = Sessions::Backend::TicketOverviewList.new(@agent2, {}, false, '123-2', 2)

    ticket = Ticket.create!(title: 'default overview test', group_id: 1, priority_id: 1, state_id: 1, customer_id: 1)

    assert(client1.asset_needed_by_updated_at?(ticket.class.to_s, ticket.id, ticket.updated_at))
    client1.asset_push(ticket, {})
    assert_not(client1.asset_needed_by_updated_at?(ticket.class.to_s, ticket.id, ticket.updated_at))

    assert(client2.asset_needed_by_updated_at?(ticket.class.to_s, ticket.id, ticket.updated_at))
    client2.asset_push(ticket, {})
    assert_not(client2.asset_needed_by_updated_at?(ticket.class.to_s, ticket.id, ticket.updated_at))

    travel 30.minutes

    assert_not(client1.asset_needed_by_updated_at?(ticket.class.to_s, ticket.id, ticket.updated_at))
    assert_not(client2.asset_needed_by_updated_at?(ticket.class.to_s, ticket.id, ticket.updated_at))

    travel 60.minutes

    assert(client1.asset_needed_by_updated_at?(ticket.class.to_s, ticket.id, ticket.updated_at))
    client1.asset_push(ticket, {})
    assert(client2.asset_needed_by_updated_at?(ticket.class.to_s, ticket.id, ticket.updated_at))
    client2.asset_push(ticket, {})

    assert_not(client1.asset_needed_by_updated_at?(ticket.class.to_s, ticket.id, ticket.updated_at))
    client1.asset_push(ticket, {})
    assert_not(client2.asset_needed_by_updated_at?(ticket.class.to_s, ticket.id, ticket.updated_at))
    client2.asset_push(ticket, {})

    ticket.touch

    assert(client1.asset_needed_by_updated_at?(ticket.class.to_s, ticket.id, ticket.updated_at))
    client1.asset_push(ticket, {})
    assert(client2.asset_needed_by_updated_at?(ticket.class.to_s, ticket.id, ticket.updated_at))
    client2.asset_push(ticket, {})

    assert_not(client1.asset_needed?(ticket))
    assert_not(client2.asset_needed?(ticket))

    travel 65.minutes

    assert(client1.asset_needed?(ticket))
    client1.asset_push(ticket, {})
    assert(client2.asset_needed?(ticket))
    client2.asset_push(ticket, {})

    assert_not(client1.asset_needed?(ticket))
    assert_not(client2.asset_needed?(ticket))

    travel_back
  end

  test 'ticket_overview_List' do

    ticket1 = Ticket.create!(title: 'default overview test 1', group_id: 1, priority_id: 1, state_id: 1, customer_id: 1)
    ticket2 = Ticket.create!(title: 'default overview test 2', group_id: 1, priority_id: 1, state_id: 1, customer_id: 1)

    client1 = Sessions::Backend::TicketOverviewList.new(@agent1, {}, false, '123-1', 2)

    result1 = client1.push
    assert(result1, 'check ticket_overview_List')
    assert(result1[1][:data][:assets])
    assert(result1[1][:data][:assets][:Overview])
    assert(result1[1][:data][:assets][:User])
    assert_equal(result1[1][:data][:assets][:Ticket][ticket1.id]['title'], ticket1.title)
    assert_equal(result1[1][:data][:assets][:Ticket][ticket2.id]['title'], ticket2.title)

    # next check should be empty / no changes
    result1 = client1.push
    assert(!result1, 'check ticket_overview_index - recall')

    # next check should be empty / no changes
    travel 3.seconds
    result1 = client1.push
    assert(!result1, 'check ticket_overview_index - recall 2')

    # create ticket
    ticket3 = Ticket.create!(title: '12323', group_id: 1, priority_id: 1, state_id: 1, customer_id: 1)
    travel 3.seconds

    result1 = client1.push
    assert(result1, 'check ticket_overview_index - recall 3')
    assert(result1[1][:data][:assets])
    assert_not(result1[1][:data][:assets][:Ticket][ticket1.id])
    assert_not(result1[1][:data][:assets][:Ticket][ticket2.id])
    assert_equal(result1[1][:data][:assets][:Ticket][ticket3.id]['title'], ticket3.title)

    travel 3.seconds

    # chnage overview
    overviews = Ticket::Overviews.all(
      current_user: @agent1,
    )
    overviews.first.touch

    result1 = client1.push
    assert(result1, 'check ticket_overview_index - recall 4')
    assert(result1[1][:data][:assets])
    assert_not(result1[1][:data][:assets][:Ticket])

    result1 = client1.push
    assert(!result1, 'check ticket_overview_index - recall 5')

    Sessions::Backend::TicketOverviewList.reset(@agent1.id)
    result1 = client1.push
    assert(!result1, 'check ticket_overview_index - recall 6')

    ticket4 = Ticket.create!(title: '12323 - 2', group_id: 1, priority_id: 1, state_id: 1, customer_id: 1)
    Sessions::Backend::TicketOverviewList.reset(@agent1.id)
    result1 = client1.push
    assert(result1, 'check ticket_overview_index - recall 7')
    assert(result1[1][:data][:assets])
    assert_not(result1[1][:data][:assets][:Ticket][ticket1.id])
    assert_not(result1[1][:data][:assets][:Ticket][ticket2.id])
    assert_not(result1[1][:data][:assets][:Ticket][ticket3.id])
    assert_equal(result1[1][:data][:assets][:Ticket][ticket4.id]['title'], ticket4.title)

    travel 65.minutes
    ticket1.touch
    result1 = client1.push
    assert(result1, 'check ticket_overview_index - recall 8')
    assert(result1[1][:data][:assets])
    assert_equal(result1[1][:data][:assets][:Ticket][ticket1.id]['title'], ticket1.title)
    assert_equal(result1[1][:data][:assets][:Ticket][ticket2.id]['title'], ticket2.title)
    assert_equal(result1[1][:data][:assets][:Ticket][ticket3.id]['title'], ticket3.title)
    assert_equal(result1[1][:data][:assets][:Ticket][ticket4.id]['title'], ticket4.title)

    travel 10.seconds
    Sessions.destroy_idle_sessions(3)

    travel_back
  end

end
