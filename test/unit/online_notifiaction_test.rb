# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'test_helper'

class OnlineNotificationTest < ActiveSupport::TestCase

  setup do
    role = Role.lookup(name: 'Agent')
    @group = Group.create_or_update(
      name:          'OnlineNotificationTest',
      updated_by_id: 1,
      created_by_id: 1
    )
    @agent_user1 = User.create_or_update(
      login:         'agent_online_notify1',
      firstname:     'Bob',
      lastname:      'Smith',
      email:         'agent_online_notify1@example.com',
      password:      'some_pass',
      active:        true,
      role_ids:      [role.id],
      group_ids:     [@group.id],
      updated_by_id: 1,
      created_by_id: 1
    )
    @agent_user2 = User.create_or_update(
      login:         'agent_online_notify2',
      firstname:     'Bob',
      lastname:      'Smith',
      email:         'agent_online_notify2@example.com',
      password:      'some_pass',
      active:        true,
      role_ids:      [role.id],
      group_ids:     [@group.id],
      updated_by_id: 1,
      created_by_id: 1
    )
    @customer_user = User.lookup(email: 'nicole.braun@zammad.org')

    calendar1 = Calendar.create_or_update(
      name:           'EU 1 - test',
      timezone:       'Europe/Berlin',
      business_hours: {
        mon: {
          active:     true,
          timeframes: [ ['00:00', '23:59'] ]
        },
        tue: {
          active:     true,
          timeframes: [ ['00:00', '23:59'] ]
        },
        wed: {
          active:     true,
          timeframes: [ ['00:00', '23:59'] ]
        },
        thu: {
          active:     true,
          timeframes: [ ['00:00', '23:59'] ]
        },
        fri: {
          active:     true,
          timeframes: [ ['00:00', '23:59'] ]
        },
        sat: {
          active:     true,
          timeframes: [ ['00:00', '23:59'] ]
        },
        sun: {
          active:     true,
          timeframes: [ ['00:00', '23:59'] ]
        },
      },
      default:        true,
      ical_url:       nil,
      updated_by_id:  1,
      created_by_id:  1,
    )

    Sla.create_or_update(
      name:                'test sla 1',
      condition:           {},
      first_response_time: 20,
      update_time:         60,
      solution_time:       120,
      calendar_id:         calendar1.id,
      updated_by_id:       1,
      created_by_id:       1,
    )

  end

  test 'ticket notification' do

    ApplicationHandleInfo.current = 'application_server'

    # case #1
    ticket1 = Ticket.create(
      group:         @group,
      customer_id:   @customer_user.id,
      owner_id:      User.lookup(login: '-').id,
      title:         'Unit Test 1 (äöüß)!',
      state_id:      Ticket::State.lookup(name: 'closed').id,
      priority_id:   Ticket::Priority.lookup(name: '2 normal').id,
      updated_by_id: @agent_user1.id,
      created_by_id: @agent_user1.id,
    )
    Ticket::Article.create(
      ticket_id:     ticket1.id,
      updated_by_id: @agent_user1.id,
      created_by_id: @agent_user1.id,
      type_id:       Ticket::Article::Type.lookup(name: 'phone').id,
      sender_id:     Ticket::Article::Sender.lookup(name: 'Customer').id,
      from:          'Unit Test <unittest@example.com>',
      body:          'Unit Test 123',
      internal:      false
    )

    # remember ticket
    tickets = []
    tickets.push ticket1

    # execute object transaction
    TransactionDispatcher.commit
    Scheduler.worker(true)

    # because it's already closed
    assert(OnlineNotification.all_seen?('Ticket', ticket1.id))
    assert_not(OnlineNotification.exists?(@agent_user1, 'Ticket', ticket1.id, 'create', @agent_user1, false))
    assert_not(OnlineNotification.exists?(@agent_user1, 'Ticket', ticket1.id, 'create', @agent_user1, true))
    assert_not(OnlineNotification.exists?(@agent_user2, 'Ticket', ticket1.id, 'create', @agent_user1, false))
    assert(OnlineNotification.exists?(@agent_user2, 'Ticket', ticket1.id, 'create', @agent_user1, true))

    ticket1.update!(
      title:         'Unit Test 1 (äöüß) - update!',
      state_id:      Ticket::State.lookup(name: 'open').id,
      priority_id:   Ticket::Priority.lookup(name: '1 low').id,
      updated_by_id: @customer_user.id,
    )

    # execute object transaction
    TransactionDispatcher.commit
    Scheduler.worker(true)

    # because it's already open
    assert_not(OnlineNotification.all_seen?('Ticket', ticket1.id))
    assert_not(OnlineNotification.exists?(@agent_user1, 'Ticket', ticket1.id, 'update', @customer_user, true))
    assert(OnlineNotification.exists?(@agent_user1, 'Ticket', ticket1.id, 'update', @customer_user, false))
    assert_not(OnlineNotification.exists?(@agent_user2, 'Ticket', ticket1.id, 'update', @customer_user, true))
    assert(OnlineNotification.exists?(@agent_user2, 'Ticket', ticket1.id, 'update', @customer_user, false))

    # case #2
    ticket2 = Ticket.create(
      group:         @group,
      customer_id:   @customer_user.id,
      owner_id:      @agent_user1.id,
      title:         'Unit Test 1 (äöüß)!',
      state_id:      Ticket::State.lookup(name: 'closed').id,
      priority_id:   Ticket::Priority.lookup(name: '2 normal').id,
      updated_by_id: @customer_user.id,
      created_by_id: @customer_user.id,
    )
    Ticket::Article.create(
      ticket_id:     ticket2.id,
      updated_by_id: @customer_user.id,
      created_by_id: @customer_user.id,
      type_id:       Ticket::Article::Type.lookup(name: 'phone').id,
      sender_id:     Ticket::Article::Sender.lookup(name: 'Customer').id,
      from:          'Unit Test <unittest@example.com>',
      body:          'Unit Test 123',
      internal:      false
    )

    # remember ticket
    tickets = []
    tickets.push ticket2

    # execute object transaction
    TransactionDispatcher.commit
    Scheduler.worker(true)

    # because it's already closed
    assert_not(OnlineNotification.all_seen?('Ticket', ticket2.id))
    assert(OnlineNotification.exists?(@agent_user1, 'Ticket', ticket2.id, 'create', @customer_user, false))
    assert_not(OnlineNotification.exists?(@agent_user1, 'Ticket', ticket2.id, 'create', @customer_user, true))
    assert_not(OnlineNotification.exists?(@agent_user2, 'Ticket', ticket2.id, 'create', @customer_user, false))
    assert_not(OnlineNotification.exists?(@agent_user2, 'Ticket', ticket2.id, 'create', @customer_user, true))

    ticket2.update!(
      title:         'Unit Test 1 (äöüß) - update!',
      state_id:      Ticket::State.lookup(name: 'open').id,
      priority_id:   Ticket::Priority.lookup(name: '1 low').id,
      updated_by_id: @customer_user.id,
    )

    # execute object transaction
    TransactionDispatcher.commit
    Scheduler.worker(true)

    # because it's already open
    assert_not(OnlineNotification.all_seen?('Ticket', ticket2.id))
    assert(OnlineNotification.exists?(@agent_user1, 'Ticket', ticket2.id, 'update', @customer_user, false))
    assert_not(OnlineNotification.exists?(@agent_user1, 'Ticket', ticket2.id, 'update', @customer_user, true))
    assert_not(OnlineNotification.exists?(@agent_user2, 'Ticket', ticket2.id, 'update', @customer_user, true))
    assert_not(OnlineNotification.exists?(@agent_user2, 'Ticket', ticket2.id, 'update', @customer_user, false))

    # case #3
    ticket3 = Ticket.create(
      group:         @group,
      customer_id:   @customer_user.id,
      owner_id:      User.lookup(login: '-').id,
      title:         'Unit Test 2 (äöüß)!',
      state_id:      Ticket::State.lookup(name: 'new').id,
      priority_id:   Ticket::Priority.lookup(name: '2 normal').id,
      updated_by_id: @agent_user1.id,
      created_by_id: @agent_user1.id,
    )
    Ticket::Article.create(
      ticket_id:     ticket3.id,
      updated_by_id: @agent_user1.id,
      created_by_id: @agent_user1.id,
      type_id:       Ticket::Article::Type.lookup(name: 'phone').id,
      sender_id:     Ticket::Article::Sender.lookup(name: 'Customer').id,
      from:          'Unit Test <unittest@example.com>',
      body:          'Unit Test 123',
      internal:      false,
    )

    # remember ticket
    tickets.push ticket3

    # execute object transaction
    TransactionDispatcher.commit
    Scheduler.worker(true)

    # because it's already new
    assert_not(OnlineNotification.all_seen?('Ticket', ticket3.id))
    assert_not(OnlineNotification.exists?(@agent_user1, 'Ticket', ticket3.id, 'create', @agent_user1, false))
    assert_not(OnlineNotification.exists?(@agent_user1, 'Ticket', ticket3.id, 'create', @agent_user1, true))
    assert(OnlineNotification.exists?(@agent_user2, 'Ticket', ticket3.id, 'create', @agent_user1, false))
    assert_not(OnlineNotification.exists?(@agent_user2, 'Ticket', ticket3.id, 'create', @agent_user1, true))

    ticket3.update!(
      title:         'Unit Test 2 (äöüß) - update!',
      state_id:      Ticket::State.lookup(name: 'closed').id,
      priority_id:   Ticket::Priority.lookup(name: '1 low').id,
      updated_by_id: @customer_user.id,
    )

    # execute object transaction
    TransactionDispatcher.commit
    Scheduler.worker(true)

    # because it's already closed
    assert(OnlineNotification.all_seen?('Ticket', ticket3.id))
    assert_equal(1, NotificationFactory::Mailer.already_sent?(ticket3, @agent_user1, 'update'))
    assert_equal(1, NotificationFactory::Mailer.already_sent?(ticket3, @agent_user2, 'update'))
    assert_not(OnlineNotification.exists?(@agent_user1, 'Ticket', ticket3.id, 'update', @customer_user, false))
    assert(OnlineNotification.exists?(@agent_user1, 'Ticket', ticket3.id, 'update', @customer_user, true))
    assert_not(OnlineNotification.exists?(@agent_user2, 'Ticket', ticket3.id, 'update', @customer_user, false))
    assert(OnlineNotification.exists?(@agent_user2, 'Ticket', ticket3.id, 'update', @customer_user, true))

    Ticket::Article.create(
      ticket_id:     ticket3.id,
      updated_by_id: @customer_user.id,
      created_by_id: @customer_user.id,
      type_id:       Ticket::Article::Type.lookup(name: 'phone').id,
      sender_id:     Ticket::Article::Sender.lookup(name: 'Customer').id,
      from:          'Unit Test <unittest@example.com>',
      body:          'Unit Test 123 # 2',
      internal:      false
    )

    # execute object transaction
    TransactionDispatcher.commit
    Scheduler.worker(true)

    # because it's already closed but an follow-up arrived later
    assert_not(OnlineNotification.all_seen?('Ticket', ticket3.id))
    assert(OnlineNotification.exists?(@agent_user1, 'Ticket', ticket3.id, 'update', @customer_user, false))
    assert(OnlineNotification.exists?(@agent_user1, 'Ticket', ticket3.id, 'update', @customer_user, true))
    assert(OnlineNotification.exists?(@agent_user2, 'Ticket', ticket3.id, 'update', @customer_user, false))
    assert(OnlineNotification.exists?(@agent_user2, 'Ticket', ticket3.id, 'update', @customer_user, true))
    assert_equal(2, NotificationFactory::Mailer.already_sent?(ticket3, @agent_user1, 'update'))
    assert_equal(2, NotificationFactory::Mailer.already_sent?(ticket3, @agent_user2, 'update'))

    # case #4
    ticket4 = Ticket.create(
      group:         @group,
      customer_id:   @customer_user.id,
      owner_id:      @agent_user1.id,
      title:         'Unit Test 3 (äöüß)!',
      state_id:      Ticket::State.lookup(name: 'new').id,
      priority_id:   Ticket::Priority.lookup(name: '2 normal').id,
      updated_by_id: @customer_user.id,
      created_by_id: @customer_user.id,
    )
    Ticket::Article.create(
      ticket_id:     ticket4.id,
      updated_by_id: @customer_user.id,
      created_by_id: @customer_user.id,
      type_id:       Ticket::Article::Type.lookup(name: 'phone').id,
      sender_id:     Ticket::Article::Sender.lookup(name: 'Customer').id,
      from:          'Unit Test <unittest@example.com>',
      body:          'Unit Test 123',
      internal:      false,
    )

    # remember ticket
    tickets.push ticket4

    # execute object transaction
    TransactionDispatcher.commit
    Scheduler.worker(true)

    # because it's already new
    assert_not(OnlineNotification.all_seen?('Ticket', ticket4.id))
    assert(OnlineNotification.exists?(@agent_user1, 'Ticket', ticket4.id, 'create', @customer_user, false))
    assert_not(OnlineNotification.exists?(@agent_user1, 'Ticket', ticket4.id, 'create', @customer_user, true))
    assert_not(OnlineNotification.exists?(@agent_user2, 'Ticket', ticket4.id, 'create', @customer_user, false))
    assert_not(OnlineNotification.exists?(@agent_user2, 'Ticket', ticket4.id, 'create', @customer_user, true))

    ticket4.update!(
      title:         'Unit Test 3 (äöüß) - update!',
      state_id:      Ticket::State.lookup(name: 'open').id,
      priority_id:   Ticket::Priority.lookup(name: '1 low').id,
      updated_by_id: @customer_user.id,
    )

    # execute object transaction
    TransactionDispatcher.commit
    Scheduler.worker(true)

    # because it's already open
    assert_not(OnlineNotification.all_seen?('Ticket', ticket4.id))
    assert(OnlineNotification.exists?(@agent_user1, 'Ticket', ticket4.id, 'update', @customer_user, false))
    assert_not(OnlineNotification.exists?(@agent_user1, 'Ticket', ticket4.id, 'update', @customer_user, true))
    assert_not(OnlineNotification.exists?(@agent_user2, 'Ticket', ticket4.id, 'update', @customer_user, false))
    assert_not(OnlineNotification.exists?(@agent_user2, 'Ticket', ticket4.id, 'update', @customer_user, true))

    # case #5
    ticket5 = Ticket.create(
      group:         @group,
      customer_id:   @customer_user.id,
      owner_id:      User.lookup(login: '-').id,
      title:         'Unit Test 4 (äöüß)!',
      state_id:      Ticket::State.lookup(name: 'new').id,
      priority_id:   Ticket::Priority.lookup( name: '2 normal').id,
      updated_by_id: @agent_user1.id,
      created_by_id: @agent_user1.id,
    )
    Ticket::Article.create(
      ticket_id:     ticket5.id,
      updated_by_id: @agent_user1.id,
      created_by_id: @agent_user1.id,
      type_id:       Ticket::Article::Type.lookup(name: 'phone').id,
      sender_id:     Ticket::Article::Sender.lookup(name: 'Customer').id,
      from:          'Unit Test <unittest@example.com>',
      body:          'Unit Test 123',
      internal:      false,
    )

    # remember ticket
    tickets.push ticket5

    # execute object transaction
    TransactionDispatcher.commit
    Scheduler.worker(true)

    # because it's already new
    assert_not(OnlineNotification.all_seen?('Ticket', ticket5.id))
    assert_not(OnlineNotification.exists?(@agent_user1, 'Ticket', ticket5.id, 'create', @agent_user1, true))
    assert_not(OnlineNotification.exists?(@agent_user1, 'Ticket', ticket5.id, 'create', @agent_user1, false))
    assert(OnlineNotification.exists?(@agent_user2, 'Ticket', ticket5.id, 'create', @agent_user1, false))
    assert_not(OnlineNotification.exists?(@agent_user2, 'Ticket', ticket5.id, 'create', @agent_user1, true))

    ticket5.update!(
      title:         'Unit Test 4 (äöüß) - update!',
      state_id:      Ticket::State.lookup(name: 'open').id,
      priority_id:   Ticket::Priority.lookup(name: '1 low').id,
      updated_by_id: @customer_user.id,
    )

    # execute object transaction
    TransactionDispatcher.commit
    Scheduler.worker(true)

    # because it's already open
    assert_not(OnlineNotification.all_seen?('Ticket', ticket5.id))
    assert(OnlineNotification.exists?(@agent_user1, 'Ticket', ticket5.id, 'update', @customer_user, false))
    assert_not(OnlineNotification.exists?(@agent_user1, 'Ticket', ticket5.id, 'update', @customer_user, true))
    assert(OnlineNotification.exists?(@agent_user2, 'Ticket', ticket5.id, 'update', @customer_user, false))
    assert_not(OnlineNotification.exists?(@agent_user2, 'Ticket', ticket5.id, 'update', @customer_user, true))

    # merge tickets - also remove notifications of merged tickets
    tickets[0].merge_to(
      ticket_id: tickets[1].id,
      user_id:   1,
    )
    Scheduler.worker(true)

    notifications = OnlineNotification.list_by_object('Ticket', tickets[0].id)
    assert(notifications.present?, 'should have notifications')
    assert(OnlineNotification.all_seen?('Ticket', tickets[0].id), 'still not seen notifications for merged ticket available')

    notifications = OnlineNotification.list_by_object('Ticket', tickets[1].id)
    assert(notifications.present?, 'should have notifications')
    assert_not(OnlineNotification.all_seen?('Ticket', tickets[1].id), 'no notifications for master ticket available')

    # delete tickets
    tickets.each do |ticket|
      ticket_id = ticket.id
      ticket.destroy
      found = Ticket.find_by(id: ticket_id)
      assert_not(found, 'Ticket destroyed')

      # check if notifications for ticket still exist
      Scheduler.worker(true)
      notifications = OnlineNotification.list_by_object('Ticket', ticket_id)
      assert(notifications.blank?, 'still notifications for destroyed ticket available')
    end
  end

  test 'ticket notification item check' do
    ticket1 = Ticket.create(
      title:         'some title',
      group:         @group,
      customer_id:   @customer_user.id,
      state:         Ticket::State.lookup(name: 'new'),
      priority:      Ticket::Priority.lookup(name: '2 normal'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert(ticket1, 'ticket created')
    Ticket::Article.create(
      ticket_id:     ticket1.id,
      from:          'some_sender@example.com',
      to:            'some_recipient@example.com',
      subject:       'some subject',
      message_id:    'some@id',
      body:          'some message article_inbound',
      internal:      false,
      sender:        Ticket::Article::Sender.lookup(name: 'Customer'),
      type:          Ticket::Article::Type.lookup(name: 'email'),
      updated_by_id: 1,
      created_by_id: 1,
    )

    assert_equal(ticket1.online_notification_seen_state, false)
    assert_equal(ticket1.online_notification_seen_state(@agent_user1), false)
    assert_equal(ticket1.online_notification_seen_state(@agent_user2), false)

    # pending reminder, just let new owner to unseed
    ticket1.update!(
      owner_id:      @agent_user1.id,
      state:         Ticket::State.lookup(name: 'pending reminder'),
      updated_by_id: @agent_user2.id,
    )

    assert_equal(ticket1.online_notification_seen_state, true)
    assert_equal(ticket1.online_notification_seen_state(@agent_user1.id), false)
    assert_equal(ticket1.online_notification_seen_state(@agent_user2.id), true)

    # pending reminder, just let new owner to unseed
    ticket1.update!(
      owner_id:      1,
      state:         Ticket::State.lookup(name: 'pending reminder'),
      updated_by_id: @agent_user2.id,
    )

    assert_equal(ticket1.online_notification_seen_state, true)
    assert_equal(ticket1.online_notification_seen_state(@agent_user1.id), false)
    assert_equal(ticket1.online_notification_seen_state(@agent_user2.id), false)

    # pending reminder, self done, all to unseed
    ticket1.update!(
      owner_id:      @agent_user1.id,
      state:         Ticket::State.lookup(name: 'pending reminder'),
      updated_by_id: @agent_user1.id,
    )

    assert_equal(ticket1.online_notification_seen_state, true)
    assert_equal(ticket1.online_notification_seen_state(@agent_user1.id), true)
    assert_equal(ticket1.online_notification_seen_state(@agent_user2.id), true)

    # pending close, all to unseen
    ticket1.update!(
      owner_id:      @agent_user1.id,
      state:         Ticket::State.lookup(name: 'pending close'),
      updated_by_id: @agent_user2.id,
    )

    assert_equal(ticket1.online_notification_seen_state, true)
    assert_equal(ticket1.online_notification_seen_state(@agent_user1.id), false)
    assert_equal(ticket1.online_notification_seen_state(@agent_user2.id), true)

    # to open, all to seen
    ticket1.update!(
      owner_id:      @agent_user1.id,
      state:         Ticket::State.lookup(name: 'open'),
      updated_by_id: @agent_user2.id,
    )

    assert_equal(ticket1.online_notification_seen_state, false)
    assert_equal(ticket1.online_notification_seen_state(@agent_user1.id), false)
    assert_equal(ticket1.online_notification_seen_state(@agent_user2.id), false)

    # to closed, all only others to seen
    ticket1.update!(
      owner_id:      @agent_user1.id,
      state:         Ticket::State.lookup(name: 'closed'),
      updated_by_id: @agent_user2.id,
    )

    assert_equal(ticket1.online_notification_seen_state, true)
    assert_equal(ticket1.online_notification_seen_state(@agent_user1.id), false)
    assert_equal(ticket1.online_notification_seen_state(@agent_user2.id), true)

    # to closed by owner self, all to seen
    ticket1.update!(
      owner_id:      @agent_user1.id,
      state:         Ticket::State.lookup(name: 'closed'),
      updated_by_id: @agent_user1.id,
    )

    assert_equal(ticket1.online_notification_seen_state, true)
    assert_equal(ticket1.online_notification_seen_state(@agent_user1.id), true)
    assert_equal(ticket1.online_notification_seen_state(@agent_user2.id), true)

    # to closed by owner self, all to seen
    ticket1.update!(
      owner_id:      @agent_user1.id,
      state:         Ticket::State.lookup(name: 'merged'),
      updated_by_id: @agent_user2.id,
    )

    assert_equal(ticket1.online_notification_seen_state, true)
    assert_equal(ticket1.online_notification_seen_state(@agent_user1.id), true)
    assert_equal(ticket1.online_notification_seen_state(@agent_user2.id), true)

  end

  test 'cleanup check' do

    ticket1 = Ticket.create(
      group:         @group,
      customer_id:   @customer_user.id,
      owner_id:      User.lookup(login: '-').id,
      title:         'Unit Test 1 (äöüß)!',
      state_id:      Ticket::State.lookup(name: 'closed').id,
      priority_id:   Ticket::Priority.lookup(name: '2 normal').id,
      updated_by_id: @agent_user1.id,
      created_by_id: @agent_user1.id,
    )

    online_notification1 = OnlineNotification.add(
      type:          'create',
      object:        'Ticket',
      o_id:          ticket1.id,
      seen:          false,
      user_id:       @agent_user1.id,
      created_by_id: 1,
      updated_by_id: 1,
      created_at:    Time.zone.now - 10.months,
      updated_at:    Time.zone.now - 10.months,
    )
    online_notification2 = OnlineNotification.add(
      type:          'create',
      object:        'Ticket',
      o_id:          ticket1.id,
      seen:          true,
      user_id:       @agent_user1.id,
      created_by_id: 1,
      updated_by_id: 1,
      created_at:    Time.zone.now - 10.months,
      updated_at:    Time.zone.now - 10.months,
    )
    online_notification3 = OnlineNotification.add(
      type:          'create',
      object:        'Ticket',
      o_id:          ticket1.id,
      seen:          false,
      user_id:       @agent_user1.id,
      created_by_id: 1,
      updated_by_id: 1,
      created_at:    Time.zone.now - 2.days,
      updated_at:    Time.zone.now - 2.days,
    )
    online_notification4 = OnlineNotification.add(
      type:          'create',
      object:        'Ticket',
      o_id:          ticket1.id,
      seen:          true,
      user_id:       @agent_user1.id,
      created_by_id: @agent_user1.id,
      updated_by_id: @agent_user1.id,
      created_at:    Time.zone.now - 2.days,
      updated_at:    Time.zone.now - 2.days,
    )
    online_notification5 = OnlineNotification.add(
      type:          'create',
      object:        'Ticket',
      o_id:          ticket1.id,
      seen:          true,
      user_id:       @agent_user1.id,
      created_by_id: @agent_user2.id,
      updated_by_id: @agent_user2.id,
      created_at:    Time.zone.now - 2.days,
      updated_at:    Time.zone.now - 2.days,
    )
    online_notification6 = OnlineNotification.add(
      type:          'create',
      object:        'Ticket',
      o_id:          ticket1.id,
      seen:          true,
      user_id:       @agent_user1.id,
      created_by_id: @agent_user1.id,
      updated_by_id: @agent_user1.id,
      created_at:    Time.zone.now - 5.minutes,
      updated_at:    Time.zone.now - 5.minutes,
    )
    online_notification7 = OnlineNotification.add(
      type:          'create',
      object:        'Ticket',
      o_id:          ticket1.id,
      seen:          true,
      user_id:       @agent_user1.id,
      created_by_id: @agent_user2.id,
      updated_by_id: @agent_user2.id,
      created_at:    Time.zone.now - 5.minutes,
      updated_at:    Time.zone.now - 5.minutes,
    )

    OnlineNotification.cleanup

    assert_not(OnlineNotification.find_by(id: online_notification1.id))
    assert_not(OnlineNotification.find_by(id: online_notification2.id))
    assert(OnlineNotification.find_by(id: online_notification3.id))
    assert_not(OnlineNotification.find_by(id: online_notification4.id))
    assert_not(OnlineNotification.find_by(id: online_notification5.id))
    assert(OnlineNotification.find_by(id: online_notification6.id))
    assert(OnlineNotification.find_by(id: online_notification7.id))
    OnlineNotification.destroy_all
  end

  test 'not existing object ref' do
    assert_raises(RuntimeError) do
      OnlineNotification.add(
        type:          'create',
        object:        'TicketNotExisting',
        o_id:          123,
        seen:          false,
        user_id:       @agent_user1.id,
        created_by_id: 1,
        updated_by_id: 1,
        created_at:    Time.zone.now - 10.months,
        updated_at:    Time.zone.now - 10.months,
      )
    end
    assert_raises(ActiveRecord::RecordNotFound) do
      OnlineNotification.add(
        type:          'create',
        object:        'Ticket',
        o_id:          123,
        seen:          false,
        user_id:       @agent_user1.id,
        created_by_id: 1,
        updated_by_id: 1,
        created_at:    Time.zone.now - 10.months,
        updated_at:    Time.zone.now - 10.months,
      )
    end
  end
end
