# encoding: utf-8
require 'test_helper'

class OnlineNotificationTest < ActiveSupport::TestCase
  role        = Role.lookup(name: 'Agent')
  group       = Group.lookup(name: 'Users')
  agent_user1 = User.create_or_update(
    login: 'agent_online_notify1',
    firstname: 'Bob',
    lastname: 'Smith',
    email: 'agent_online_notify1@example.com',
    password: 'some_pass',
    active: true,
    role_ids: [role.id],
    group_ids: [group.id],
    updated_by_id: 1,
    created_by_id: 1
  )
  agent_user2 = User.create_or_update(
    login: 'agent_online_notify2',
    firstname: 'Bob',
    lastname: 'Smith',
    email: 'agent_online_notify2@example.com',
    password: 'some_pass',
    active: true,
    role_ids: [role.id],
    group_ids: [group.id],
    updated_by_id: 1,
    created_by_id: 1
  )
  customer_user = User.lookup(email: 'nicole.braun@zammad.org')

  test 'ticket notification' do
    tests = [

      # test 1
      {
        create: {
          ticket: {
            group_id: Group.lookup( name: 'Users' ).id,
            customer_id: customer_user.id,
            owner_id: User.lookup( login: '-' ).id,
            title: 'Unit Test 1 (äöüß)!',
            state_id: Ticket::State.lookup( name: 'closed' ).id,
            priority_id: Ticket::Priority.lookup( name: '2 normal' ).id,
            updated_by_id: agent_user1.id,
            created_by_id: agent_user1.id,
          },
          article: {
            updated_by_id: agent_user1.id,
            created_by_id: agent_user1.id,
            type_id: Ticket::Article::Type.lookup( name: 'phone' ).id,
            sender_id: Ticket::Article::Sender.lookup( name: 'Customer' ).id,
            from: 'Unit Test <unittest@example.com>',
            body: 'Unit Test 123',
            internal: false
          },
          online_notification: {
            seen_only_exists: true,
          },
        },
        update: {
          ticket: {
            title: 'Unit Test 1 (äöüß) - update!',
            state_id: Ticket::State.lookup( name: 'open' ).id,
            priority_id: Ticket::Priority.lookup( name: '1 low' ).id,
            updated_by_id: customer_user.id,
          },
          online_notification: {
            seen_only_exists: false,
          },
        },
        check: [
          {
            type: 'create',
            object: 'Ticket',
            created_by_id: agent_user1.id,
          },
          {
            type: 'update',
            object: 'Ticket',
            created_by_id: customer_user.id,
          },
        ],
      },

      # test 2
      {
        create: {
          ticket: {
            group_id: Group.lookup( name: 'Users' ).id,
            customer_id: customer_user.id,
            owner_id: User.lookup( login: '-' ).id,
            title: 'Unit Test 2 (äöüß)!',
            state_id: Ticket::State.lookup( name: 'new' ).id,
            priority_id: Ticket::Priority.lookup( name: '2 normal' ).id,
            updated_by_id: agent_user1.id,
            created_by_id: agent_user1.id,
          },
          article: {
            updated_by_id: agent_user1.id,
            created_by_id: agent_user1.id,
            type_id: Ticket::Article::Type.lookup( name: 'phone' ).id,
            sender_id: Ticket::Article::Sender.lookup( name: 'Customer' ).id,
            from: 'Unit Test <unittest@example.com>',
            body: 'Unit Test 123',
            internal: false
          },
          online_notification: {
            seen_only_exists: false,
          },
        },
        update: {
          ticket: {
            title: 'Unit Test 2 (äöüß) - update!',
            state_id: Ticket::State.lookup( name: 'closed' ).id,
            priority_id: Ticket::Priority.lookup( name: '1 low' ).id,
            updated_by_id: customer_user.id,
          },
          online_notification: {
            seen_only_exists: true,
          },
        },
        check: [
          {
            type: 'create',
            object: 'Ticket',
            created_by_id: agent_user1.id,
          },
          {
            type: 'update',
            object: 'Ticket',
            created_by_id: customer_user.id,
          },
        ],
      },

      # test 3
      {
        create: {
          ticket: {
            group_id: Group.lookup( name: 'Users' ).id,
            customer_id: customer_user.id,
            owner_id: User.lookup( login: '-' ).id,
            title: 'Unit Test 3 (äöüß)!',
            state_id: Ticket::State.lookup( name: 'new' ).id,
            priority_id: Ticket::Priority.lookup( name: '2 normal' ).id,
            updated_by_id: agent_user1.id,
            created_by_id: agent_user1.id,
          },
          article: {
            updated_by_id: agent_user1.id,
            created_by_id: agent_user1.id,
            type_id: Ticket::Article::Type.lookup( name: 'phone' ).id,
            sender_id: Ticket::Article::Sender.lookup( name: 'Customer' ).id,
            from: 'Unit Test <unittest@example.com>',
            body: 'Unit Test 123',
            internal: false
          },
          online_notification: {
            seen_only_exists: false,
          },
        },
        update: {
          ticket: {
            title: 'Unit Test 3 (äöüß) - update!',
            state_id: Ticket::State.lookup( name: 'open' ).id,
            priority_id: Ticket::Priority.lookup( name: '1 low' ).id,
            updated_by_id: customer_user.id,
          },
          online_notification: {
            seen_only_exists: false,
          },
        },
        check: [
          {
            type: 'create',
            object: 'Ticket',
            created_by_id: agent_user1.id,
          },
          {
            type: 'update',
            object: 'Ticket',
            created_by_id: customer_user.id,
          },
        ],
      },

      # test 4
      {
        create: {
          ticket: {
            group_id: Group.lookup( name: 'Users' ).id,
            customer_id: customer_user.id,
            owner_id: User.lookup( login: '-' ).id,
            title: 'Unit Test 4 (äöüß)!',
            state_id: Ticket::State.lookup( name: 'new' ).id,
            priority_id: Ticket::Priority.lookup( name: '2 normal' ).id,
            updated_by_id: agent_user1.id,
            created_by_id: agent_user1.id,
          },
          article: {
            updated_by_id: agent_user1.id,
            created_by_id: agent_user1.id,
            type_id: Ticket::Article::Type.lookup( name: 'phone' ).id,
            sender_id: Ticket::Article::Sender.lookup( name: 'Customer' ).id,
            from: 'Unit Test <unittest@example.com>',
            body: 'Unit Test 123',
            internal: false
          },
          online_notification: {
            seen_only_exists: false,
          },
        },
        update: {
          ticket: {
            title: 'Unit Test 4 (äöüß) - update!',
            state_id: Ticket::State.lookup( name: 'open' ).id,
            priority_id: Ticket::Priority.lookup( name: '1 low' ).id,
            updated_by_id: customer_user.id,
          },
          online_notification: {
            seen_only_exists: false,
          },
        },
        check: [
          {
            type: 'create',
            object: 'Ticket',
            created_by_id: agent_user1.id,
          },
          {
            type: 'update',
            object: 'Ticket',
            created_by_id: customer_user.id,
          },
        ],
      },
    ]
    tickets = []
    tests.each { |test|

      ticket                 = Ticket.create( test[:create][:ticket] )
      test[:check][0][:o_id] = ticket.id
      test[:check][1][:o_id] = ticket.id

      test[:create][:article][:ticket_id] = ticket.id
      article = Ticket::Article.create( test[:create][:article] )

      assert_equal( ticket.class.to_s, 'Ticket' )

      # execute ticket events
      Observer::Ticket::Notification.transaction
      #puts Delayed::Job.all.inspect
      Delayed::Worker.new.work_off

      # check online notifications
      if test[:create][:online_notification]
        if test[:create][:online_notification][:seen_only_exists]
          notifications = OnlineNotification.list_by_object( 'Ticket', ticket.id )
          assert( notification_seen_only_exists_exists( notifications ), 'not seen notifications for ticket available')
        else
          notifications = OnlineNotification.list_by_object( 'Ticket', ticket.id )
          assert( !notification_seen_only_exists_exists( notifications ), 'seen notifications for ticket available')
        end
      end

      # update ticket
      if test[:update][:ticket]
        ticket.update_attributes( test[:update][:ticket] )
      end

      # execute ticket events
      Observer::Ticket::Notification.transaction
      #puts Delayed::Job.all.inspect
      Delayed::Worker.new.work_off

      # remember ticket
      tickets.push ticket

      # check online notifications
      notification_check( OnlineNotification.list(agent_user2, 10), test[:check] )

      # check online notifications
      next if !test[:update][:online_notification]

      if test[:update][:online_notification][:seen_only_exists]
        notifications = OnlineNotification.list_by_object( 'Ticket', ticket.id )
        assert( notification_seen_only_exists_exists( notifications ), 'not seen notifications for ticket available')
      else
        notifications = OnlineNotification.list_by_object( 'Ticket', ticket.id )
        assert( !notification_seen_only_exists_exists( notifications ), 'seen notifications for ticket available')
      end
    }

    # merge tickets - also remove notifications of merged tickets
    tickets[2].merge_to(
      ticket_id: tickets[3].id,
      user_id: 1,
    )
    Delayed::Worker.new.work_off
    notifications = OnlineNotification.list_by_object( 'Ticket', tickets[2].id )
    assert( !notifications.empty?, 'should have notifications')
    assert( notification_seen_only_exists_exists(notifications), 'still not seen notifications for merged ticket available')

    notifications = OnlineNotification.list_by_object( 'Ticket', tickets[3].id )
    assert( !notifications.empty?, 'should have notifications')
    assert( !notification_seen_only_exists_exists(notifications), 'no notifications for master ticket available')

    # delete tickets
    tickets.each { |ticket|
      ticket_id = ticket.id
      ticket.destroy
      found = Ticket.where( id: ticket_id ).first
      assert( !found, 'Ticket destroyed')

      # check if notifications for ticket still exist
      Delayed::Worker.new.work_off
      notifications = OnlineNotification.list_by_object( 'Ticket', ticket_id )
      assert( notifications.empty?, 'still notifications for destroyed ticket available')
    }
  end

  test 'ticket notification item check' do
    ticket1 = Ticket.create(
      title: 'some title',
      group: Group.lookup(name: 'Users'),
      customer_id: 2,
      state: Ticket::State.lookup(name: 'new'),
      priority: Ticket::Priority.lookup(name: '2 normal'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert( ticket1, 'ticket created' )
    article_inbound = Ticket::Article.create(
      ticket_id: ticket1.id,
      from: 'some_sender@example.com',
      to: 'some_recipient@example.com',
      subject: 'some subject',
      message_id: 'some@id',
      body: 'some message article_inbound',
      internal: false,
      sender: Ticket::Article::Sender.lookup(name: 'Customer'),
      type: Ticket::Article::Type.lookup(name: 'email'),
      updated_by_id: 1,
      created_by_id: 1,
    )

    assert_equal(ticket1.online_notification_seen_state, false)
    assert_equal(ticket1.online_notification_seen_state(agent_user1), false)
    assert_equal(ticket1.online_notification_seen_state(agent_user2), false)

    # pending reminder, just let new owner to unseed
    ticket1.update_attributes(
      owner_id: agent_user1.id,
      state: Ticket::State.lookup(name: 'pending reminder'),
      updated_by_id: agent_user2.id,
    )

    assert_equal(ticket1.online_notification_seen_state, true)
    assert_equal(ticket1.online_notification_seen_state(agent_user1.id), false)
    assert_equal(ticket1.online_notification_seen_state(agent_user2.id), true)

    # pending reminder, just let new owner to unseed
    ticket1.update_attributes(
      owner_id: 1,
      state: Ticket::State.lookup(name: 'pending reminder'),
      updated_by_id: agent_user2.id,
    )

    assert_equal(ticket1.online_notification_seen_state, true)
    assert_equal(ticket1.online_notification_seen_state(agent_user1.id), false)
    assert_equal(ticket1.online_notification_seen_state(agent_user2.id), false)

    # pending reminder, self done, all to unseed
    ticket1.update_attributes(
      owner_id: agent_user1.id,
      state: Ticket::State.lookup(name: 'pending reminder'),
      updated_by_id: agent_user1.id,
    )

    assert_equal(ticket1.online_notification_seen_state, true)
    assert_equal(ticket1.online_notification_seen_state(agent_user1.id), true)
    assert_equal(ticket1.online_notification_seen_state(agent_user2.id), true)

    # pending close, all to unseen
    ticket1.update_attributes(
      owner_id: agent_user1.id,
      state: Ticket::State.lookup(name: 'pending close'),
      updated_by_id: agent_user2.id,
    )

    assert_equal(ticket1.online_notification_seen_state, true)
    assert_equal(ticket1.online_notification_seen_state(agent_user1.id), false)
    assert_equal(ticket1.online_notification_seen_state(agent_user2.id), true)

    # to open, all to seen
    ticket1.update_attributes(
      owner_id: agent_user1.id,
      state: Ticket::State.lookup(name: 'open'),
      updated_by_id: agent_user2.id,
    )

    assert_equal(ticket1.online_notification_seen_state, false)
    assert_equal(ticket1.online_notification_seen_state(agent_user1.id), false)
    assert_equal(ticket1.online_notification_seen_state(agent_user2.id), false)

    # to closed, all only others to seen
    ticket1.update_attributes(
      owner_id: agent_user1.id,
      state: Ticket::State.lookup(name: 'closed'),
      updated_by_id: agent_user2.id,
    )

    assert_equal(ticket1.online_notification_seen_state, true)
    assert_equal(ticket1.online_notification_seen_state(agent_user1.id), false)
    assert_equal(ticket1.online_notification_seen_state(agent_user2.id), true)

    # to closed by owner self, all to seen
    ticket1.update_attributes(
      owner_id: agent_user1.id,
      state: Ticket::State.lookup(name: 'closed'),
      updated_by_id: agent_user1.id,
    )

    assert_equal(ticket1.online_notification_seen_state, true)
    assert_equal(ticket1.online_notification_seen_state(agent_user1.id), true)
    assert_equal(ticket1.online_notification_seen_state(agent_user2.id), true)

    # to closed by owner self, all to seen
    ticket1.update_attributes(
      owner_id: agent_user1.id,
      state: Ticket::State.lookup(name: 'merged'),
      updated_by_id: agent_user2.id,
    )

    assert_equal(ticket1.online_notification_seen_state, true)
    assert_equal(ticket1.online_notification_seen_state(agent_user1.id), true)
    assert_equal(ticket1.online_notification_seen_state(agent_user2.id), true)

  end

  test 'cleanup check' do
    online_notification1 = OnlineNotification.add(
      type:          'create',
      object:        'Ticket',
      o_id:          123,
      seen:          false,
      user_id:       agent_user1.id,
      created_by_id: 1,
      updated_by_id: 1,
      created_at:    Time.zone.now - 10.months,
      updated_at:    Time.zone.now - 10.months,
    )
    online_notification2 = OnlineNotification.add(
      type:          'create',
      object:        'Ticket',
      o_id:          123,
      seen:          true,
      user_id:       agent_user1.id,
      created_by_id: 1,
      updated_by_id: 1,
      created_at:    Time.zone.now - 10.months,
      updated_at:    Time.zone.now - 10.months,
    )
    online_notification3 = OnlineNotification.add(
      type:          'create',
      object:        'Ticket',
      o_id:          123,
      seen:          false,
      user_id:       agent_user1.id,
      created_by_id: 1,
      updated_by_id: 1,
      created_at:    Time.zone.now - 2.days,
      updated_at:    Time.zone.now - 2.days,
    )
    online_notification4 = OnlineNotification.add(
      type:          'create',
      object:        'Ticket',
      o_id:          123,
      seen:          true,
      user_id:       agent_user1.id,
      created_by_id: agent_user1.id,
      updated_by_id: agent_user1.id,
      created_at:    Time.zone.now - 2.days,
      updated_at:    Time.zone.now - 2.days,
    )
    online_notification5 = OnlineNotification.add(
      type:          'create',
      object:        'Ticket',
      o_id:          123,
      seen:          true,
      user_id:       agent_user1.id,
      created_by_id: agent_user2.id,
      updated_by_id: agent_user2.id,
      created_at:    Time.zone.now - 2.days,
      updated_at:    Time.zone.now - 2.days,
    )
    online_notification6 = OnlineNotification.add(
      type:          'create',
      object:        'Ticket',
      o_id:          123,
      seen:          true,
      user_id:       agent_user1.id,
      created_by_id: agent_user1.id,
      updated_by_id: agent_user1.id,
      created_at:    Time.zone.now - 10.minutes,
      updated_at:    Time.zone.now - 10.minutes,
    )
    online_notification7 = OnlineNotification.add(
      type:          'create',
      object:        'Ticket',
      o_id:          123,
      seen:          true,
      user_id:       agent_user1.id,
      created_by_id: agent_user2.id,
      updated_by_id: agent_user2.id,
      created_at:    Time.zone.now - 10.minutes,
      updated_at:    Time.zone.now - 10.minutes,
    )

    OnlineNotification.cleanup

    assert(!OnlineNotification.find_by(id: online_notification1.id))
    assert(!OnlineNotification.find_by(id: online_notification2.id))
    assert(OnlineNotification.find_by(id: online_notification3.id))
    assert(!OnlineNotification.find_by(id: online_notification4.id))
    assert(!OnlineNotification.find_by(id: online_notification5.id))
    assert(OnlineNotification.find_by(id: online_notification6.id))
    assert(OnlineNotification.find_by(id: online_notification7.id))

  end

  def notification_check(online_notifications, checks)
    checks.each { |check_item|
      hit = false
      online_notifications.each {|onine_notification|

        next if onine_notification['o_id'] != check_item[:o_id]
        next if onine_notification['object'] != check_item[:object]
        next if onine_notification['type'] != check_item[:type]
        next if onine_notification['created_by_id'] != check_item[:created_by_id]

        hit = true

        break
      }
      #puts "--- #{online_notifications.inspect}"
      assert( hit, "online notification exists not #{check_item.inspect}" )
    }
  end

  def notification_seen_only_exists_exists(online_notifications)
    online_notifications.each {|onine_notification|
      return false if !onine_notification['seen']
    }
    true
  end
end
