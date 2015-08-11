## encoding: utf-8
require 'integration_test_helper'

class CalendarSubscriptionsTicketsTest < ActiveSupport::TestCase

  user = User.create(
    firstname: 'CalendarSubscriptions',
    lastname: 'Testuser',
    email: 'calendar_subscriptions_testuser@example.com',
    updated_by_id: 1,
    created_by_id: 1,
  )

  user_not_assigned = User.find(1)

  sla = Sla.create(
    name: 'sla 1',
    condition: {},
    data: {
      'Mon' => 'Mon', 'Tue' => 'Tue', 'Wed' => 'Wed', 'Thu' => 'Thu', 'Fri' => 'Fri', 'Sat' => 'Sat', 'Sun' => 'Sun',
      'beginning_of_workday' => '9:00',
      'end_of_workday'       => '18:00',
    },
    timezone: 'Europe/Berlin',
    first_response_time: 10,
    update_time: 10,
    close_time: 10,
    active: true,
    updated_by_id: 1,
    created_by_id: 1,
  )

  tickets = [
    {
      owner: user,
      title: 'new 1',
      group: Group.lookup( name: 'Users'),
      customer_id: user.id,
      state: Ticket::State.lookup( name: 'new' ),
      priority: Ticket::Priority.lookup( name: '2 normal' ),
      updated_by_id: 1,
      created_by_id: 1,
    },
    {
      owner: user_not_assigned,
      title: 'new 2',
      group: Group.lookup( name: 'Users'),
      customer_id: user.id,
      state: Ticket::State.lookup( name: 'new' ),
      priority: Ticket::Priority.lookup( name: '2 normal' ),
      updated_by_id: 1,
      created_by_id: 1,
    },
    {
      owner: user,
      title: 'open 1',
      group: Group.lookup( name: 'Users'),
      customer_id: user.id,
      state: Ticket::State.lookup( name: 'open' ),
      priority: Ticket::Priority.lookup( name: '2 normal' ),
      updated_by_id: 1,
      created_by_id: 1,
    },
    {
      owner: user_not_assigned,
      title: 'open 2',
      group: Group.lookup( name: 'Users'),
      customer_id: user.id,
      state: Ticket::State.lookup( name: 'open' ),
      priority: Ticket::Priority.lookup( name: '2 normal' ),
      updated_by_id: 1,
      created_by_id: 1,
    },
    {
      owner: user,
      title: 'pending reminder 1',
      group: Group.lookup( name: 'Users'),
      customer_id: user.id,
      state: Ticket::State.lookup( name: 'pending reminder' ),
      pending_time: Time.zone.parse('1977-10-27 22:00:00 +0000'),
      priority: Ticket::Priority.lookup( name: '2 normal' ),
      updated_by_id: 1,
      created_by_id: 1,
    },
    {
      owner: user,
      title: 'pending reminder 2',
      group: Group.lookup( name: 'Users'),
      customer_id: user.id,
      state: Ticket::State.lookup( name: 'pending reminder' ),
      pending_time: DateTime.tomorrow,
      priority: Ticket::Priority.lookup( name: '2 normal' ),
      updated_by_id: 1,
      created_by_id: 1,
    },
    {
      owner: user_not_assigned,
      title: 'pending reminder 3',
      group: Group.lookup( name: 'Users'),
      customer_id: user.id,
      state: Ticket::State.lookup( name: 'pending reminder' ),
      pending_time: Time.zone.parse('1977-10-27 22:00:00 +0000'),
      priority: Ticket::Priority.lookup( name: '2 normal' ),
      updated_by_id: 1,
      created_by_id: 1,
    },
    {
      owner: user_not_assigned,
      title: 'pending reminder 4',
      group: Group.lookup( name: 'Users'),
      customer_id: user.id,
      state: Ticket::State.lookup( name: 'pending reminder' ),
      pending_time: DateTime.tomorrow,
      priority: Ticket::Priority.lookup( name: '2 normal' ),
      updated_by_id: 1,
      created_by_id: 1,
    },
    {
      owner: user,
      title: 'pending close 1',
      group: Group.lookup( name: 'Users'),
      customer_id: user.id,
      state: Ticket::State.lookup( name: 'pending close' ),
      pending_time: Time.zone.parse('1977-10-27 22:00:00 +0000'),
      priority: Ticket::Priority.lookup( name: '2 normal' ),
      updated_by_id: 1,
      created_by_id: 1,
    },
    {
      owner: user,
      title: 'pending close 2',
      group: Group.lookup( name: 'Users'),
      customer_id: user.id,
      state: Ticket::State.lookup( name: 'pending close' ),
      pending_time: DateTime.tomorrow,
      priority: Ticket::Priority.lookup( name: '2 normal' ),
      updated_by_id: 1,
      created_by_id: 1,
    },
    {
      owner: user_not_assigned,
      title: 'pending close 3',
      group: Group.lookup( name: 'Users'),
      customer_id: user.id,
      state: Ticket::State.lookup( name: 'pending close' ),
      pending_time: Time.zone.parse('1977-10-27 22:00:00 +0000'),
      priority: Ticket::Priority.lookup( name: '2 normal' ),
      updated_by_id: 1,
      created_by_id: 1,
    },
    {
      owner: user_not_assigned,
      title: 'pending close 4',
      group: Group.lookup( name: 'Users'),
      customer_id: user.id,
      state: Ticket::State.lookup( name: 'pending close' ),
      pending_time: DateTime.tomorrow,
      priority: Ticket::Priority.lookup( name: '2 normal' ),
      updated_by_id: 1,
      created_by_id: 1,
    },
    {
      owner: user,
      title: 'escalation 1',
      group: Group.lookup( name: 'Users'),
      customer_id: user.id,
      state: Ticket::State.lookup( name: 'open' ),
      priority: Ticket::Priority.lookup( name: '2 normal' ),
      created_at: '2013-03-21 09:30:00 UTC',
      updated_at: '2013-03-21 09:30:00 UTC',
      updated_by_id: 1,
      created_by_id: 1,
    },
    {
      owner: user_not_assigned,
      title: 'escalation 2',
      group: Group.lookup( name: 'Users'),
      customer_id: user.id,
      state: Ticket::State.lookup( name: 'open' ),
      priority: Ticket::Priority.lookup( name: '2 normal' ),
      created_at: '2013-03-21 09:30:00 UTC',
      updated_at: '2013-03-21 09:30:00 UTC',
      updated_by_id: 1,
      created_by_id: 1,
    },
  ]

  tickets.each { |ticket|

    Ticket.create( ticket )
  }

  defaults_disabled = {
    escalation: {
      own: false,
      not_assigned: false,
    },
    new_open: {
      own: false,
      not_assigned: false,
    },
    pending: {
      own: false,
      not_assigned: false,
    }
  }

  test 'new_open' do

    tests = [
      {
        count: 0,
        name: 'none',
        preferences: {
          new_open: {
            own: false,
            not_assigned: false,
          }
        },
        owner_ids: []
      },
      {
        count: 3,
        name: 'owner',
        preferences: {
          new_open: {
            own: true,
            not_assigned: false,
          }
        },
        owner_ids: [user.id]
      },
      {
        count: 3,
        name: 'not_assigned',
        preferences: {
          new_open: {
            own: false,
            not_assigned: true,
          }
        },
        owner_ids: [user_not_assigned.id]
      },
      {
        count: 6,
        name: 'owner+not_assigned',
        preferences: {
          new_open: {
            own: true,
            not_assigned: true,
          }
        },
        owner_ids: [user.id, user_not_assigned.id]
      },
    ]

    tests.each { |test_data|

      preferences = defaults_disabled.merge( test_data[:preferences] )

      user.preferences[:calendar_subscriptions]           = {}
      user.preferences[:calendar_subscriptions][:tickets] = preferences

      calendar_subscriptions_ticket = CalendarSubscriptions::Tickets.new( user, preferences )
      event_data                    = calendar_subscriptions_ticket.new_open

      assert_equal( test_data[:count], event_data.length, "#{test_data[:name]} event count" )

      calendar_subscriptions = CalendarSubscriptions.new( user )
      ical                   = calendar_subscriptions.all

      event_data.each { |event|

        contained = false
        if ical =~ /#{event[:summary]}/
          contained = true
        end

        assert( contained, "#{test_data[:name]} new_open ical contains '#{event[:summary]}'" )
      }
    }
  end

  test 'pending' do

    tests = [
      {
        count: 0,
        name: 'none',
        preferences: {
          pending: {
            own: false,
            not_assigned: false,
          }
        },
        owner_ids: []
      },
      {
        count: 4,
        name: 'owner',
        preferences: {
          pending: {
            own: true,
            not_assigned: false,
          }
        },
        owner_ids: [user.id]
      },
      {
        count: 4,
        name: 'not_assigned',
        preferences: {
          pending: {
            own: false,
            not_assigned: true,
          }
        },
        owner_ids: [user_not_assigned.id]
      },
      {
        count: 8,
        name: 'owner+not_assigned',
        preferences: {
          pending: {
            own: true,
            not_assigned: true,
          }
        },
        owner_ids: [user.id, user_not_assigned.id]
      },
    ]

    tests.each { |test_data|

      preferences = defaults_disabled.merge( test_data[:preferences] )

      user.preferences[:calendar_subscriptions]           = {}
      user.preferences[:calendar_subscriptions][:tickets] = preferences

      calendar_subscriptions_ticket = CalendarSubscriptions::Tickets.new( user, preferences )
      event_data                    = calendar_subscriptions_ticket.pending

      assert_equal( test_data[:count], event_data.length, "#{test_data[:name]} event count" )

      calendar_subscriptions = CalendarSubscriptions.new( user )
      ical                   = calendar_subscriptions.all

      event_data.each { |event|

        contained = false
        if ical =~ /#{event[:summary]}/
          contained = true
        end

        assert( contained, "#{test_data[:name]} pending ical contains '#{event[:summary]}'" )
      }
    }
  end

  test 'escalation' do

    tests = [
      {
        count: 0,
        name: 'none',
        preferences: {
          escalation: {
            own: false,
            not_assigned: false,
          }
        },
        owner_ids: []
      },
      {
        count: 7,
        name: 'owner',
        preferences: {
          escalation: {
            own: true,
            not_assigned: false,
          }
        },
        owner_ids: [user.id]
      },
      {
        count: 7,
        name: 'not_assigned',
        preferences: {
          escalation: {
            own: false,
            not_assigned: true,
          }
        },
        owner_ids: [user_not_assigned.id]
      },
      {
        count: 12,
        name: 'owner+not_assigned',
        preferences: {
          escalation: {
            own: true,
            not_assigned: true,
          }
        },
        owner_ids: [user.id, user_not_assigned.id]
      },
    ]

    tests.each { |test_data|

      preferences = defaults_disabled.merge( test_data[:preferences] )

      user.preferences[:calendar_subscriptions]           = {}
      user.preferences[:calendar_subscriptions][:tickets] = preferences

      calendar_subscriptions_ticket = CalendarSubscriptions::Tickets.new( user, preferences )
      event_data                    = calendar_subscriptions_ticket.escalation

      assert_equal( test_data[:count], event_data.length, "#{test_data[:name]} event count" )

      calendar_subscriptions = CalendarSubscriptions.new( user )
      ical                   = calendar_subscriptions.all

      event_data.each { |event|

        contained = false
        if ical =~ /#{event[:summary]}/
          contained = true
        end

        assert( contained, "#{test_data[:name]} escalation ical contains '#{event[:summary]}'" )
      }
    }
  end

end
