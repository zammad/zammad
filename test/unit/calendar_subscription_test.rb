# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'test_helper'

class CalendarSubscriptionTest < ActiveSupport::TestCase
  test 'default test' do

    # create base
    group_default = Group.lookup(name: 'Users')
    group_calendar = Group.create!(
      name:          'CalendarSubscription',
      updated_by_id: 1,
      created_by_id: 1,
    )
    roles = Role.where(name: 'Agent')
    agent1 = User.create!(
      login:         'ticket-calendar-subscription-agent1@example.com',
      firstname:     'Notification',
      lastname:      'Agent1',
      email:         'ticket-calendar-subscription-agent1@example.com',
      password:      'agentpw',
      active:        true,
      roles:         roles,
      groups:        [group_calendar],
      preferences:   {},
      updated_by_id: 1,
      created_by_id: 1,
    )
    agent2 = User.create!(
      login:         'ticket-calendar-subscription-agent2@example.com',
      firstname:     'Notification',
      lastname:      'Agent2',
      email:         'ticket-calendar-subscription-agent2@example.com',
      password:      'agentpw',
      active:        true,
      roles:         roles,
      groups:        [group_default],
      preferences:   {},
      updated_at:    '2016-02-05 16:38:00',
      updated_by_id: 1,
      created_by_id: 1,
    )
    roles = Role.where(name: 'Customer')
    organization1 = Organization.create_if_not_exists(
      name:          'Selector Org',
      updated_at:    '2016-02-05 16:37:00',
      updated_by_id: 1,
      created_by_id: 1,
    )
    customer1 = User.create!(
      login:           'ticket-calendar-subscription-customer1@example.com',
      firstname:       'Notification',
      lastname:        'Customer1',
      email:           'ticket-calendar-subscription-customer1@example.com',
      password:        'customerpw',
      active:          true,
      organization_id: organization1.id,
      roles:           roles,
      preferences:     {},
      updated_at:      '2016-02-05 16:37:00',
      updated_by_id:   1,
      created_by_id:   1,
    )
    User.create!(
      login:           'ticket-calendar-subscription-customer2@example.com',
      firstname:       'Notification',
      lastname:        'Customer2',
      email:           'ticket-calendar-subscription-customer2@example.com',
      password:        'customerpw',
      active:          true,
      organization_id: nil,
      roles:           roles,
      preferences:     {},
      updated_at:      '2016-02-05 16:37:00',
      updated_by_id:   1,
      created_by_id:   1,
    )

    Ticket.destroy_all

    ticket1 = Ticket.create!(
      title:         'some title1 - new - group_calendar',
      group:         group_calendar,
      customer_id:   customer1.id,
      owner_id:      agent1.id,
      state:         Ticket::State.lookup(name: 'new'),
      priority:      Ticket::Priority.lookup(name: '2 normal'),
      created_at:    '2016-02-05 16:37:00',
      updated_at:    '2016-02-05 16:37:00',
      updated_by_id: 1,
      created_by_id: 1,
    )
    ticket2 = Ticket.create!(
      title:         'some title1 - new - group_default',
      group:         group_default,
      customer_id:   customer1.id,
      owner_id:      agent2.id,
      state:         Ticket::State.lookup(name: 'new'),
      priority:      Ticket::Priority.lookup(name: '2 normal'),
      created_at:    '2016-02-05 16:38:00',
      updated_at:    '2016-02-05 16:38:00',
      updated_by_id: 1,
      created_by_id: 1,
    )
    ticket3 = Ticket.create!(
      title:         'some title1 - pending - group_calendar',
      group:         group_calendar,
      customer_id:   customer1.id,
      owner_id:      agent1.id,
      state:         Ticket::State.lookup(name: 'pending reminder'),
      pending_time:  '2016-02-07 16:37:00',
      priority:      Ticket::Priority.lookup(name: '2 normal'),
      created_at:    '2016-02-05 16:39:00',
      updated_at:    '2016-02-05 16:39:00',
      updated_by_id: 1,
      created_by_id: 1,
    )
    ticket4 = Ticket.create!(
      title:         'some title1 - pending - group_default',
      group:         group_default,
      customer_id:   customer1.id,
      owner_id:      agent2.id,
      state:         Ticket::State.lookup(name: 'pending reminder'),
      pending_time:  '2016-02-07 16:38:00',
      priority:      Ticket::Priority.lookup(name: '2 normal'),
      created_at:    '2016-02-05 16:40:00',
      updated_at:    '2016-02-05 16:40:00',
      updated_by_id: 1,
      created_by_id: 1,
    )
    ticket5 = Ticket.create!(
      title:         'some title1 - escalation - group_calendar',
      group:         group_calendar,
      customer_id:   customer1.id,
      owner_id:      agent1.id,
      state:         Ticket::State.lookup(name: 'new'),
      priority:      Ticket::Priority.lookup(name: '2 normal'),
      created_at:    '2016-02-05 16:41:00',
      updated_at:    '2016-02-05 16:41:00',
      updated_by_id: 1,
      created_by_id: 1,
    )
    ticket5.update_columns(escalation_at: '2016-02-07 17:39:00')

    ticket6 = Ticket.create!(
      title:         'some title1 - escalation - group_default',
      group:         group_default,
      customer_id:   customer1.id,
      owner_id:      agent2.id,
      state:         Ticket::State.lookup(name: 'new'),
      priority:      Ticket::Priority.lookup(name: '2 normal'),
      created_at:    '2016-02-05 16:42:00',
      updated_at:    '2016-02-05 16:42:00',
      updated_by_id: 1,
      created_by_id: 1,
    )
    ticket6.update_columns(escalation_at: '2016-02-07 16:37:00')

    ticket7 = Ticket.create!(
      title:         'some title2 - new - group_calendar',
      group:         group_calendar,
      customer_id:   customer1.id,
      owner_id:      1,
      state:         Ticket::State.lookup(name: 'new'),
      priority:      Ticket::Priority.lookup(name: '2 normal'),
      created_at:    '2016-02-05 17:37:00',
      updated_at:    '2016-02-05 17:37:00',
      updated_by_id: 1,
      created_by_id: 1,
    )
    ticket8 = Ticket.create!(
      title:         'some title2 - new - group_default',
      group:         group_default,
      customer_id:   customer1.id,
      owner_id:      1,
      state:         Ticket::State.lookup(name: 'new'),
      priority:      Ticket::Priority.lookup(name: '2 normal'),
      created_at:    '2016-02-05 17:38:00',
      updated_at:    '2016-02-05 17:38:00',
      updated_by_id: 1,
      created_by_id: 1,
    )
    ticket9 = Ticket.create!(
      title:         'some title2 - pending - group_calendar',
      group:         group_calendar,
      customer_id:   customer1.id,
      owner_id:      1,
      state:         Ticket::State.lookup(name: 'pending reminder'),
      pending_time:  '2016-02-08 16:37:00',
      priority:      Ticket::Priority.lookup(name: '2 normal'),
      created_at:    '2016-02-05 17:39:00',
      updated_at:    '2016-02-05 17:39:00',
      updated_by_id: 1,
      created_by_id: 1,
    )
    ticket10 = Ticket.create!(
      title:         'some title2 - pending - group_default',
      group:         group_default,
      customer_id:   customer1.id,
      owner_id:      1,
      state:         Ticket::State.lookup(name: 'pending reminder'),
      pending_time:  '2016-02-08 16:38:00',
      priority:      Ticket::Priority.lookup(name: '2 normal'),
      created_at:    '2016-02-05 17:40:00',
      updated_at:    '2016-02-05 17:40:00',
      updated_by_id: 1,
      created_by_id: 1,
    )
    ticket11 = Ticket.create!(
      title:         'some title2 - escalation - group_calendar',
      group:         group_calendar,
      customer_id:   customer1.id,
      owner_id:      1,
      state:         Ticket::State.lookup(name: 'new'),
      priority:      Ticket::Priority.lookup(name: '2 normal'),
      created_at:    '2016-02-05 17:41:00',
      updated_at:    '2016-02-05 17:41:00',
      updated_by_id: 1,
      created_by_id: 1,
    )
    ticket11.update_columns(escalation_at: '2016-02-08 18:37:00')

    ticket12 = Ticket.create!(
      title:         'some title2 - escalation - group_default',
      group:         group_default,
      customer_id:   customer1.id,
      owner_id:      1,
      state:         Ticket::State.lookup(name: 'new'),
      priority:      Ticket::Priority.lookup(name: '2 normal'),
      created_at:    '2016-02-05 17:42:00',
      updated_at:    '2016-02-05 17:42:00',
      updated_by_id: 1,
      created_by_id: 1,
    )
    ticket12.update_columns(escalation_at: '2016-02-08 18:38:00')
    Cache.clear # set escalation_at manually, to clear cache to have correct content later

    # check agent 1
    calendar_subscriptions = CalendarSubscriptions.new(agent1)

    ical_file = calendar_subscriptions.all
    cals      = Icalendar::Calendar.parse(ical_file)
    assert_equal(cals.count, 1)
    cal = cals.first
    assert_equal(cals.count, 1)
    assert_equal(cal.events.count, 4)

    assert_equal(cal.events[0].dtstart, Time.zone.today)
    assert_equal(cal.events[0].summary, 'new ticket: \'some title1 - escalation - group_calendar\'')
    assert_equal(cal.events[0].description, "T##{ticket5.number}")
    assert_equal(cal.events[0].has_alarm?, false)

    assert_equal(cal.events[1].dtstart, Time.zone.today)
    assert_equal(cal.events[1].summary, 'new ticket: \'some title1 - new - group_calendar\'')
    assert_equal(cal.events[1].description, "T##{ticket1.number}")
    assert_equal(cal.events[1].has_alarm?, false)

    assert_equal(cal.events[2].dtstart, Time.zone.today)
    assert_equal(cal.events[2].summary, 'pending reminder ticket: \'some title1 - pending - group_calendar\' customer: Notification Customer1 (Selector Org)')
    assert_equal(cal.events[2].description, "T##{ticket3.number}")
    assert_equal(cal.events[2].has_alarm?, false)

    assert_equal(cal.events[3].dtstart, Time.zone.today)
    assert_equal(cal.events[3].summary, 'ticket escalation: \'some title1 - escalation - group_calendar\' customer: Notification Customer1 (Selector Org)')
    assert_equal(cal.events[3].description, "T##{ticket5.number}")
    assert_equal(cal.events[3].has_alarm?, false)

    if !agent1.preferences[:calendar_subscriptions]
      agent1.preferences[:calendar_subscriptions] = {}
    end
    agent1.preferences[:calendar_subscriptions][:tickets] = {
      escalation: {
        own:          true,
        not_assigned: true,
      },
      new_open:   {
        own:          true,
        not_assigned: true,
      },
      pending:    {
        own:          true,
        not_assigned: true,
      },
      alarm:      true,
    }
    agent1.save!

    calendar_subscriptions = CalendarSubscriptions.new(agent1)

    ical_file = calendar_subscriptions.all
    cals      = Icalendar::Calendar.parse(ical_file)
    assert_equal(cals.count, 1)
    cal = cals.first
    assert_equal(cals.count, 1)
    assert_equal(cal.events.count, 8)

    assert_equal(cal.events[0].dtstart, Time.zone.today)
    assert_equal(cal.events[0].summary, 'new ticket: \'some title2 - escalation - group_calendar\'')
    assert_equal(cal.events[0].description, "T##{ticket11.number}")
    assert_equal(cal.events[0].has_alarm?, false)

    assert_equal(cal.events[1].dtstart, Time.zone.today)
    assert_equal(cal.events[1].summary, 'new ticket: \'some title2 - new - group_calendar\'')
    assert_equal(cal.events[1].description, "T##{ticket7.number}")
    assert_equal(cal.events[1].has_alarm?, false)

    assert_equal(cal.events[2].dtstart, Time.zone.today)
    assert_equal(cal.events[2].summary, 'new ticket: \'some title1 - escalation - group_calendar\'')
    assert_equal(cal.events[2].description, "T##{ticket5.number}")
    assert_equal(cal.events[2].has_alarm?, false)

    assert_equal(cal.events[3].dtstart, Time.zone.today)
    assert_equal(cal.events[3].summary, 'new ticket: \'some title1 - new - group_calendar\'')
    assert_equal(cal.events[3].description, "T##{ticket1.number}")
    assert_equal(cal.events[3].has_alarm?, false)

    assert_equal(cal.events[4].dtstart, Time.zone.today)
    assert_equal(cal.events[4].summary, 'pending reminder ticket: \'some title2 - pending - group_calendar\' customer: Notification Customer1 (Selector Org)')
    assert_equal(cal.events[4].description, "T##{ticket9.number}")
    assert_equal(cal.events[4].has_alarm?, true)

    assert_equal(cal.events[5].dtstart, Time.zone.today)
    assert_equal(cal.events[5].summary, 'pending reminder ticket: \'some title1 - pending - group_calendar\' customer: Notification Customer1 (Selector Org)')
    assert_equal(cal.events[5].description, "T##{ticket3.number}")
    assert_equal(cal.events[5].has_alarm?, true)

    assert_equal(cal.events[6].dtstart, Time.zone.today)
    assert_equal(cal.events[6].summary, 'ticket escalation: \'some title2 - escalation - group_calendar\' customer: Notification Customer1 (Selector Org)')
    assert_equal(cal.events[6].description, "T##{ticket11.number}")
    assert_equal(cal.events[6].has_alarm?, true)

    assert_equal(cal.events[7].dtstart, Time.zone.today)
    assert_equal(cal.events[7].summary, 'ticket escalation: \'some title1 - escalation - group_calendar\' customer: Notification Customer1 (Selector Org)')
    assert_equal(cal.events[7].description, "T##{ticket5.number}")
    assert_equal(cal.events[7].has_alarm?, true)

    # check agent 2
    calendar_subscriptions = CalendarSubscriptions.new(agent2)

    ical_file = calendar_subscriptions.all
    cals      = Icalendar::Calendar.parse(ical_file)
    assert_equal(cals.count, 1)
    cal = cals.first
    assert_equal(cals.count, 1)
    assert_equal(cal.events.count, 4)

    assert_equal(cal.events[0].dtstart, Time.zone.today)
    assert_equal(cal.events[0].summary, 'new ticket: \'some title1 - escalation - group_default\'')
    assert_equal(cal.events[0].description, "T##{ticket6.number}")

    assert_equal(cal.events[1].dtstart, Time.zone.today)
    assert_equal(cal.events[1].summary, 'new ticket: \'some title1 - new - group_default\'')
    assert_equal(cal.events[1].description, "T##{ticket2.number}")

    assert_equal(cal.events[2].dtstart, Time.zone.today)
    assert_equal(cal.events[2].summary, 'pending reminder ticket: \'some title1 - pending - group_default\' customer: Notification Customer1 (Selector Org)')
    assert_equal(cal.events[2].description, "T##{ticket4.number}")

    assert_equal(cal.events[3].dtstart, Time.zone.today)
    assert_equal(cal.events[3].summary, 'ticket escalation: \'some title1 - escalation - group_default\' customer: Notification Customer1 (Selector Org)')
    assert_equal(cal.events[3].description, "T##{ticket6.number}")

    if !agent2.preferences[:calendar_subscriptions]
      agent2.preferences[:calendar_subscriptions] = {}
    end
    agent2.preferences[:calendar_subscriptions][:tickets] = {
      escalation: {
        own:          true,
        not_assigned: true,
      },
      new_open:   {
        own:          true,
        not_assigned: true,
      },
      pending:    {
        own:          true,
        not_assigned: true,
      },
      alarm:      false,
    }
    agent2.save!

    calendar_subscriptions = CalendarSubscriptions.new(agent2)

    ical_file = calendar_subscriptions.all
    cals      = Icalendar::Calendar.parse(ical_file)
    assert_equal(cals.count, 1)
    cal = cals.first
    assert_equal(cals.count, 1)
    assert_equal(cal.events.count, 8)

    assert_equal(cal.events[0].dtstart, Time.zone.today)
    assert_equal(cal.events[0].summary, 'new ticket: \'some title2 - escalation - group_default\'')
    assert_equal(cal.events[0].description, "T##{ticket12.number}")
    assert_equal(cal.events[0].has_alarm?, false)

    assert_equal(cal.events[1].dtstart, Time.zone.today)
    assert_equal(cal.events[1].summary, 'new ticket: \'some title2 - new - group_default\'')
    assert_equal(cal.events[1].description, "T##{ticket8.number}")
    assert_equal(cal.events[1].has_alarm?, false)

    assert_equal(cal.events[2].dtstart, Time.zone.today)
    assert_equal(cal.events[2].summary, 'new ticket: \'some title1 - escalation - group_default\'')
    assert_equal(cal.events[2].description, "T##{ticket6.number}")
    assert_equal(cal.events[2].has_alarm?, false)

    assert_equal(cal.events[3].dtstart, Time.zone.today)
    assert_equal(cal.events[3].summary, 'new ticket: \'some title1 - new - group_default\'')
    assert_equal(cal.events[3].description, "T##{ticket2.number}")
    assert_equal(cal.events[3].has_alarm?, false)

    assert_equal(cal.events[4].dtstart, Time.zone.today)
    assert_equal(cal.events[4].summary, 'pending reminder ticket: \'some title2 - pending - group_default\' customer: Notification Customer1 (Selector Org)')
    assert_equal(cal.events[4].description, "T##{ticket10.number}")
    assert_equal(cal.events[4].has_alarm?, false)

    assert_equal(cal.events[5].dtstart, Time.zone.today)
    assert_equal(cal.events[5].summary, 'pending reminder ticket: \'some title1 - pending - group_default\' customer: Notification Customer1 (Selector Org)')
    assert_equal(cal.events[5].description, "T##{ticket4.number}")
    assert_equal(cal.events[5].has_alarm?, false)

    assert_equal(cal.events[6].dtstart, Time.zone.today)
    assert_equal(cal.events[6].summary, 'ticket escalation: \'some title2 - escalation - group_default\' customer: Notification Customer1 (Selector Org)')
    assert_equal(cal.events[6].description, "T##{ticket12.number}")
    assert_equal(cal.events[6].has_alarm?, false)

    assert_equal(cal.events[7].dtstart, Time.zone.today)
    assert_equal(cal.events[7].summary, 'ticket escalation: \'some title1 - escalation - group_default\' customer: Notification Customer1 (Selector Org)')
    assert_equal(cal.events[7].description, "T##{ticket6.number}")
    assert_equal(cal.events[7].has_alarm?, false)

  end

end
