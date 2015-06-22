# encoding: utf-8
require 'integration_test_helper'

class ICalTicketTest < ActiveSupport::TestCase

  user = User.create(
    firstname: 'iCal',
    lastname: 'Testuser',
    email: 'ical_testuser@example.com',
    updated_by_id: 1,
    created_by_id: 1,
  );

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
  ]

  tickets.each { |ticket|

    Ticket.create( ticket )
  }

  test 'new_open' do

    event_data = ICal::Ticket.new_open( user )

    assert_equal( 3, event_data.length, 'event count' )

    ical = ICal.to_ical( event_data )

    event_data.each{ |event|

      contained = false
      if ical =~ /#{event[:summary]}/
        contained = true
      end

      assert( contained, "ical contains '#{event[:summary]}'" )
    }
  end

  test 'pending' do

    event_data = ICal::Ticket.pending( user )

    assert_equal( 4, event_data.length, 'event count' )

    ical = ICal.to_ical( event_data )

    event_data.each{ |event|

      contained = false
      if ical =~ /#{event[:summary]}/
        contained = true
      end

      assert( contained, "ical contains '#{event[:summary]}'" )
    }
  end

  test 'escalation' do

    event_data = ICal::Ticket.escalation( user )

    assert_equal( 7, event_data.length, 'event count' )

    ical = ICal.to_ical( event_data )

    event_data.each{ |event|

      contained = false
      if ical =~ /#{event[:summary]}/
        contained = true
      end

      assert( contained, "ical contains '#{event[:summary]}'" )
    }
  end
end
