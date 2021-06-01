# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'test_helper'

class TicketNotificationTest < ActiveSupport::TestCase
  setup do
    Setting.set('timezone_default', 'Europe/Berlin')
    Trigger.create_or_update(
      name:                 'auto reply - new ticket',
      condition:            {
        'ticket.action'   => {
          'operator' => 'is',
          'value'    => 'create',
        },
        'ticket.state_id' => {
          'operator' => 'is not',
          'value'    => Ticket::State.lookup(name: 'closed').id,
        },
        'article.type_id' => {
          'operator' => 'is',
          'value'    => [
            Ticket::Article::Type.lookup(name: 'email').id,
            Ticket::Article::Type.lookup(name: 'phone').id,
            Ticket::Article::Type.lookup(name: 'web').id,
          ],
        },
      },
      perform:              {
        'notification.email' => {
          # rubocop:disable Lint/InterpolationCheck
          'body'      => '<p>Your request (Ticket##{ticket.number}) has been received and will be reviewed by our support staff.<p>
<br/>
<p>To provide additional information, please reply to this email or click on the following link:
<a href="#{config.http_type}://#{config.fqdn}/#ticket/zoom/#{ticket.id}">#{config.http_type}://#{config.fqdn}/#ticket/zoom/#{ticket.id}</a>
</p>
<br/>
<p><i><a href="http://zammad.com">Zammad</a>, your customer support system</i></p>',
          'recipient' => 'ticket_customer',
          'subject'   => 'Thanks for your inquiry (#{ticket.title})',
          # rubocop:enable Lint/InterpolationCheck
        },
      },
      disable_notification: true,
      active:               true,
      created_by_id:        1,
      updated_by_id:        1,
    )

    # create @agent1 & @agent2
    Group.create_or_update(
      name:          'TicketNotificationTest',
      updated_by_id: 1,
      created_by_id: 1
    )
    groups = Group.where(name: 'TicketNotificationTest')
    roles  = Role.where(name: 'Agent')
    @agent1 = User.create_or_update(
      login:         'ticket-notification-agent1@example.com',
      firstname:     'Notification',
      lastname:      'Agent1',
      email:         'ticket-notification-agent1@example.com',
      password:      'agentpw',
      out_of_office: false,
      active:        true,
      roles:         roles,
      groups:        groups,
      preferences:   {
        locale: 'de-de',
      },
      updated_by_id: 1,
      created_by_id: 1,
    )
    @agent2 = User.create_or_update(
      login:         'ticket-notification-agent2@example.com',
      firstname:     'Notification',
      lastname:      'Agent2',
      email:         'ticket-notification-agent2@example.com',
      password:      'agentpw',
      out_of_office: false,
      active:        true,
      roles:         roles,
      groups:        groups,
      preferences:   {
        locale:   'en-us',
        timezone: 'America/St_Lucia',
      },
      updated_by_id: 1,
      created_by_id: 1,
    )
    @agent3 = User.create_or_update(
      login:         'ticket-notification-agent3@example.com',
      firstname:     'Notification',
      lastname:      'Agent3',
      email:         'ticket-notification-agent3@example.com',
      password:      'agentpw',
      out_of_office: false,
      active:        true,
      roles:         roles,
      groups:        groups,
      preferences:   {
        locale: 'de-de',
      },
      updated_by_id: 1,
      created_by_id: 1,
    )
    @agent4 = User.create_or_update(
      login:         'ticket-notification-agent4@example.com',
      firstname:     'Notification',
      lastname:      'Agent4',
      email:         'ticket-notification-agent4@example.com',
      password:      'agentpw',
      out_of_office: false,
      active:        true,
      roles:         roles,
      groups:        groups,
      preferences:   {
        locale: 'de-de',
      },
      updated_by_id: 1,
      created_by_id: 1,
    )
    Group.create_if_not_exists(
      name:          'WithoutAccess',
      note:          'Test for notification check.',
      updated_by_id: 1,
      created_by_id: 1
    )

    # create @customer
    roles = Role.where(name: 'Customer')
    @customer = User.create_or_update(
      login:         'ticket-notification-customer@example.com',
      firstname:     'Notification',
      lastname:      'Customer',
      email:         'ticket-notification-customer@example.com',
      password:      'agentpw',
      active:        true,
      roles:         roles,
      groups:        groups,
      updated_by_id: 1,
      created_by_id: 1,
    )
  end

  test 'ticket notification - to all agents / to explicit agents' do

    # create ticket in group
    ApplicationHandleInfo.current = 'scheduler.postmaster'
    ticket1 = Ticket.create!(
      title:         'some notification test 1',
      group:         Group.lookup(name: 'TicketNotificationTest'),
      customer:      @customer,
      state:         Ticket::State.lookup(name: 'new'),
      priority:      Ticket::Priority.lookup(name: '2 normal'),
      updated_by_id: @agent1.id,
      created_by_id: @agent1.id,
    )
    Ticket::Article.create!(
      ticket_id:     ticket1.id,
      from:          'some_sender@example.com',
      to:            'some_recipient@example.com',
      subject:       'some subject',
      message_id:    'some@id',
      body:          'some message',
      internal:      false,
      sender:        Ticket::Article::Sender.where(name: 'Customer').first,
      type:          Ticket::Article::Type.where(name: 'email').first,
      updated_by_id: @agent1.id,
      created_by_id: @agent1.id,
    )
    assert(ticket1)

    # execute object transaction
    TransactionDispatcher.commit
    Scheduler.worker(true)

    # verify notifications to @agent1 + @agent2
    assert_equal(1, NotificationFactory::Mailer.already_sent?(ticket1, @agent1, 'email'), ticket1.id)
    assert_equal(1, NotificationFactory::Mailer.already_sent?(ticket1, @agent2, 'email'), ticket1.id)

    # create ticket in group
    ApplicationHandleInfo.current = 'application_server'
    ticket1 = Ticket.create!(
      title:         'some notification test 2',
      group:         Group.lookup(name: 'TicketNotificationTest'),
      customer:      @customer,
      state:         Ticket::State.lookup(name: 'new'),
      priority:      Ticket::Priority.lookup(name: '2 normal'),
      updated_by_id: @agent1.id,
      created_by_id: @agent1.id,
    )
    Ticket::Article.create!(
      ticket_id:     ticket1.id,
      from:          'some_sender@example.com',
      to:            'some_recipient@example.com',
      subject:       'some subject',
      message_id:    'some@id',
      body:          'some message',
      internal:      false,
      sender:        Ticket::Article::Sender.where(name: 'Customer').first,
      type:          Ticket::Article::Type.where(name: 'email').first,
      updated_by_id: @agent1.id,
      created_by_id: @agent1.id,
    )
    assert(ticket1)

    # execute object transaction
    TransactionDispatcher.commit
    Scheduler.worker(true)

    # verify notifications to @agent1 + @agent2
    assert_equal(0, NotificationFactory::Mailer.already_sent?(ticket1, @agent1, 'email'), ticket1.id)
    assert_equal(1, NotificationFactory::Mailer.already_sent?(ticket1, @agent2, 'email'), ticket1.id)
  end

  test 'ticket notification - simple' do

    # create ticket in group
    ApplicationHandleInfo.current = 'application_server'
    ticket1 = Ticket.create!(
      title:         'some notification test 3',
      group:         Group.lookup(name: 'TicketNotificationTest'),
      customer:      @customer,
      state:         Ticket::State.lookup(name: 'new'),
      priority:      Ticket::Priority.lookup(name: '2 normal'),
      updated_by_id: @customer.id,
      created_by_id: @customer.id,
    )
    Ticket::Article.create!(
      ticket_id:     ticket1.id,
      from:          'some_sender@example.com',
      to:            'some_recipient@example.com',
      subject:       'some subject',
      message_id:    'some@id',
      body:          'some message',
      internal:      false,
      sender:        Ticket::Article::Sender.where(name: 'Customer').first,
      type:          Ticket::Article::Type.where(name: 'email').first,
      updated_by_id: @customer.id,
      created_by_id: @customer.id,
    )
    assert(ticket1, 'ticket created - ticket notification simple')

    # execute object transaction
    TransactionDispatcher.commit
    Scheduler.worker(true)

    # verify notifications to @agent1 + @agent2
    assert_equal(1, NotificationFactory::Mailer.already_sent?(ticket1, @agent1, 'email'), ticket1.id)
    assert_equal(1, NotificationFactory::Mailer.already_sent?(ticket1, @agent2, 'email'), ticket1.id)

    # update ticket attributes
    ticket1.title    = "#{ticket1.title} - #2"
    ticket1.priority = Ticket::Priority.lookup(name: '3 high')
    ticket1.save!

    # execute object transaction
    TransactionDispatcher.commit
    Scheduler.worker(true)

    # verify notifications to @agent1 + @agent2
    assert_equal(2, NotificationFactory::Mailer.already_sent?(ticket1, @agent1, 'email'), ticket1.id)
    assert_equal(2, NotificationFactory::Mailer.already_sent?(ticket1, @agent2, 'email'), ticket1.id)

    # add article to ticket
    Ticket::Article.create!(
      ticket_id:     ticket1.id,
      from:          'some person',
      subject:       'some note',
      body:          'some message',
      internal:      true,
      sender:        Ticket::Article::Sender.where(name: 'Agent').first,
      type:          Ticket::Article::Type.where(name: 'note').first,
      updated_by_id: @agent1.id,
      created_by_id: @agent1.id,
    )

    # execute object transaction
    TransactionDispatcher.commit
    Scheduler.worker(true)

    # verify notifications to not to @agent1 but to @agent2
    assert_equal(2, NotificationFactory::Mailer.already_sent?(ticket1, @agent1, 'email'), ticket1.id)
    assert_equal(3, NotificationFactory::Mailer.already_sent?(ticket1, @agent2, 'email'), ticket1.id)

    # update ticket by user
    ticket1.owner_id      = @agent1.id
    ticket1.updated_by_id = @agent1.id
    ticket1.save!
    Ticket::Article.create!(
      ticket_id:     ticket1.id,
      from:          'some person',
      subject:       'some note',
      body:          'some message',
      internal:      true,
      sender:        Ticket::Article::Sender.where(name: 'Agent').first,
      type:          Ticket::Article::Type.where(name: 'note').first,
      updated_by_id: @agent1.id,
      created_by_id: @agent1.id,
    )

    # execute object transaction
    TransactionDispatcher.commit
    Scheduler.worker(true)

    # verify notifications to not to @agent1 but to @agent2
    assert_equal(2, NotificationFactory::Mailer.already_sent?(ticket1, @agent1, 'email'), ticket1.id)
    assert_equal(3, NotificationFactory::Mailer.already_sent?(ticket1, @agent2, 'email'), ticket1.id)

    # create ticket with @agent1 as owner
    ticket2 = Ticket.create!(
      title:         'some notification test 4',
      group:         Group.lookup(name: 'TicketNotificationTest'),
      customer_id:   2,
      owner_id:      @agent1.id,
      state:         Ticket::State.lookup(name: 'new'),
      priority:      Ticket::Priority.lookup(name: '2 normal'),
      updated_by_id: @agent1.id,
      created_by_id: @agent1.id,
    )
    Ticket::Article.create!(
      ticket_id:     ticket2.id,
      from:          'some_sender@example.com',
      to:            'some_recipient@example.com',
      subject:       'some subject',
      message_id:    'some@id',
      body:          'some message',
      internal:      false,
      sender:        Ticket::Article::Sender.where(name: 'Agent').first,
      type:          Ticket::Article::Type.where(name: 'phone').first,
      updated_by_id: @agent1.id,
      created_by_id: @agent1.id,
    )

    # execute object transaction
    TransactionDispatcher.commit
    Scheduler.worker(true)
    assert(ticket2, 'ticket created')

    # verify notifications to no one
    assert_equal(0, NotificationFactory::Mailer.already_sent?(ticket2, @agent1, 'email'), ticket2.id)
    assert_equal(0, NotificationFactory::Mailer.already_sent?(ticket2, @agent2, 'email'), ticket2.id)

    # update ticket
    ticket2.title         = "#{ticket2.title} - #2"
    ticket2.updated_by_id = @agent1.id
    ticket2.priority      = Ticket::Priority.lookup(name: '3 high')
    ticket2.save!

    # execute object transaction
    TransactionDispatcher.commit
    Scheduler.worker(true)

    # verify notifications to none
    assert_equal(0, NotificationFactory::Mailer.already_sent?(ticket2, @agent1, 'email'), ticket2.id)
    assert_equal(0, NotificationFactory::Mailer.already_sent?(ticket2, @agent2, 'email'), ticket2.id)

    # update ticket
    ticket2.title         = "#{ticket2.title} - #3"
    ticket2.updated_by_id = @agent2.id
    ticket2.priority      = Ticket::Priority.lookup(name: '2 normal')
    ticket2.save!

    # execute object transaction
    TransactionDispatcher.commit
    Scheduler.worker(true)

    # verify notifications to @agent1 and not to @agent2
    assert_equal(1, NotificationFactory::Mailer.already_sent?(ticket2, @agent1, 'email'), ticket2.id)
    assert_equal(0, NotificationFactory::Mailer.already_sent?(ticket2, @agent2, 'email'), ticket2.id)

    # create ticket with @agent2 and @agent1 as owner
    ticket3 = Ticket.create!(
      title:         'some notification test 5',
      group:         Group.lookup(name: 'TicketNotificationTest'),
      customer_id:   2,
      owner_id:      @agent1.id,
      state:         Ticket::State.lookup(name: 'new'),
      priority:      Ticket::Priority.lookup(name: '2 normal'),
      updated_by_id: @agent2.id,
      created_by_id: @agent2.id,
    )
    article_inbound = Ticket::Article.create!(
      ticket_id:     ticket3.id,
      from:          'some_sender@example.com',
      to:            'some_recipient@example.com',
      subject:       'some subject',
      message_id:    'some@id',
      body:          'some message',
      internal:      false,
      sender:        Ticket::Article::Sender.where(name: 'Agent').first,
      type:          Ticket::Article::Type.where(name: 'phone').first,
      updated_by_id: @agent2.id,
      created_by_id: @agent2.id,
    )

    # execute object transaction
    TransactionDispatcher.commit
    Scheduler.worker(true)
    assert(ticket3, 'ticket created')

    # verify notifications to @agent1 and not to @agent2
    assert_equal(1, NotificationFactory::Mailer.already_sent?(ticket3, @agent1, 'email'), ticket3.id)
    assert_equal(0, NotificationFactory::Mailer.already_sent?(ticket3, @agent2, 'email'), ticket3.id)

    # update ticket
    ticket3.title         = "#{ticket3.title} - #2"
    ticket3.updated_by_id = @agent1.id
    ticket3.priority      = Ticket::Priority.lookup(name: '3 high')
    ticket3.save!

    # execute object transaction
    TransactionDispatcher.commit
    Scheduler.worker(true)

    # verify notifications to no one
    assert_equal(1, NotificationFactory::Mailer.already_sent?(ticket3, @agent1, 'email'), ticket3.id)
    assert_equal(0, NotificationFactory::Mailer.already_sent?(ticket3, @agent2, 'email'), ticket3.id)

    # update ticket
    ticket3.title         = "#{ticket3.title} - #3"
    ticket3.updated_by_id = @agent2.id
    ticket3.priority      = Ticket::Priority.lookup(name: '2 normal')
    ticket3.save!

    # execute object transaction
    TransactionDispatcher.commit
    Scheduler.worker(true)

    # verify notifications to @agent1 and not to @agent2
    assert_equal(2, NotificationFactory::Mailer.already_sent?(ticket3, @agent1, 'email'), ticket3.id)
    assert_equal(0, NotificationFactory::Mailer.already_sent?(ticket3, @agent2, 'email'), ticket3.id)

    # update article / not notification should be sent
    article_inbound.internal = true
    article_inbound.save!

    # execute object transaction
    TransactionDispatcher.commit
    Scheduler.worker(true)

    # verify notifications not to @agent1 and not to @agent2
    assert_equal(2, NotificationFactory::Mailer.already_sent?(ticket3, @agent1, 'email'), ticket3.id)
    assert_equal(0, NotificationFactory::Mailer.already_sent?(ticket3, @agent2, 'email'), ticket3.id)

    delete = ticket1.destroy
    assert(delete, 'ticket1 destroy')

    delete = ticket2.destroy
    assert(delete, 'ticket2 destroy')

    delete = ticket3.destroy
    assert(delete, 'ticket3 destroy')

  end

  test 'ticket notification - no notification' do

    # create ticket in group
    ticket1 = Ticket.create!(
      title:         'some notification test 1 - no notification',
      group:         Group.lookup(name: 'TicketNotificationTest'),
      customer:      @customer,
      state:         Ticket::State.lookup(name: 'new'),
      priority:      Ticket::Priority.lookup(name: '2 normal'),
      updated_by_id: @customer.id,
      created_by_id: @customer.id,
    )
    Ticket::Article.create!(
      ticket_id:     ticket1.id,
      from:          'some_sender@example.com',
      to:            'some_recipient@example.com',
      subject:       'some subject',
      message_id:    'some@id',
      body:          'some message',
      internal:      false,
      sender:        Ticket::Article::Sender.where(name: 'Customer').first,
      type:          Ticket::Article::Type.where(name: 'email').first,
      updated_by_id: @customer.id,
      created_by_id: @customer.id,
    )
    assert(ticket1, 'ticket created - ticket no notification')

    # execute object transaction
    TransactionDispatcher.commit(disable_notification: true)
    Scheduler.worker(true)

    # verify notifications to @agent1 + @agent2
    assert_equal(0, NotificationFactory::Mailer.already_sent?(ticket1, @agent1, 'email'), ticket1.id)
    assert_equal(0, NotificationFactory::Mailer.already_sent?(ticket1, @agent2, 'email'), ticket1.id)

  end

  test 'ticket notification - z preferences tests' do

    @agent1.preferences['notification_config']['matrix']['create']['criteria']['owned_by_me'] = true
    @agent1.preferences['notification_config']['matrix']['create']['criteria']['owned_by_nobody'] = false
    @agent1.preferences['notification_config']['matrix']['create']['criteria']['no'] = false
    @agent1.preferences['notification_config']['matrix']['update']['criteria']['owned_by_me'] = true
    @agent1.preferences['notification_config']['matrix']['update']['criteria']['owned_by_nobody'] = false
    @agent1.preferences['notification_config']['matrix']['update']['criteria']['no'] = false
    @agent1.save!

    @agent2.preferences['notification_config']['matrix']['create']['criteria']['owned_by_me'] = false
    @agent2.preferences['notification_config']['matrix']['create']['criteria']['owned_by_nobody'] = false
    @agent2.preferences['notification_config']['matrix']['create']['criteria']['no'] = true
    @agent2.preferences['notification_config']['matrix']['update']['criteria']['owned_by_me'] = false
    @agent2.preferences['notification_config']['matrix']['update']['criteria']['owned_by_nobody'] = false
    @agent2.preferences['notification_config']['matrix']['update']['criteria']['no'] = true
    @agent2.save!

    # create ticket in group
    ApplicationHandleInfo.current = 'scheduler.postmaster'
    ticket1 = Ticket.create!(
      title:         'some notification test - z preferences tests 1',
      group:         Group.lookup(name: 'TicketNotificationTest'),
      customer:      @customer,
      state:         Ticket::State.lookup(name: 'new'),
      priority:      Ticket::Priority.lookup(name: '2 normal'),
      updated_by_id: @customer.id,
      created_by_id: @customer.id,
    )
    Ticket::Article.create!(
      ticket_id:     ticket1.id,
      from:          'some_sender@example.com',
      to:            'some_recipient@example.com',
      subject:       'some subject',
      message_id:    'some@id',
      body:          'some message',
      internal:      false,
      sender:        Ticket::Article::Sender.where(name: 'Customer').first,
      type:          Ticket::Article::Type.where(name: 'email').first,
      updated_by_id: @customer.id,
      created_by_id: @customer.id,
    )

    # execute object transaction
    TransactionDispatcher.commit
    Scheduler.worker(true)

    # verify notifications to @agent1 + @agent2
    assert_equal(0, NotificationFactory::Mailer.already_sent?(ticket1, @agent1, 'email'), ticket1.id)
    assert_equal(1, NotificationFactory::Mailer.already_sent?(ticket1, @agent2, 'email'), ticket1.id)

    # update ticket attributes
    ticket1.title    = "#{ticket1.title} - #2"
    ticket1.priority = Ticket::Priority.lookup(name: '3 high')
    ticket1.save!

    # execute object transaction
    TransactionDispatcher.commit
    Scheduler.worker(true)

    # verify notifications to @agent1 + @agent2
    assert_equal(0, NotificationFactory::Mailer.already_sent?(ticket1, @agent1, 'email'), ticket1.id)
    assert_equal(2, NotificationFactory::Mailer.already_sent?(ticket1, @agent2, 'email'), ticket1.id)

    # create ticket in group
    ticket2 = Ticket.create!(
      title:         'some notification test - z preferences tests 2',
      group:         Group.lookup(name: 'TicketNotificationTest'),
      customer:      @customer,
      owner:         @agent1,
      state:         Ticket::State.lookup(name: 'new'),
      priority:      Ticket::Priority.lookup(name: '2 normal'),
      updated_by_id: @customer.id,
      created_by_id: @customer.id,
    )
    Ticket::Article.create!(
      ticket_id:     ticket2.id,
      from:          'some_sender@example.com',
      to:            'some_recipient@example.com',
      subject:       'some subject',
      message_id:    'some@id',
      body:          'some message',
      internal:      false,
      sender:        Ticket::Article::Sender.where(name: 'Customer').first,
      type:          Ticket::Article::Type.where(name: 'email').first,
      updated_by_id: @customer.id,
      created_by_id: @customer.id,
    )

    # execute object transaction
    TransactionDispatcher.commit
    Scheduler.worker(true)

    # verify notifications to @agent1 + @agent2
    assert_equal(1, NotificationFactory::Mailer.already_sent?(ticket2, @agent1, 'email'), ticket2.id)
    assert_equal(1, NotificationFactory::Mailer.already_sent?(ticket2, @agent2, 'email'), ticket2.id)

    # update ticket attributes
    ticket2.title    = "#{ticket2.title} - #2"
    ticket2.priority = Ticket::Priority.lookup(name: '3 high')
    ticket2.save!

    # execute object transaction
    TransactionDispatcher.commit
    Scheduler.worker(true)

    # verify notifications to @agent1 + @agent2
    assert_equal(2, NotificationFactory::Mailer.already_sent?(ticket2, @agent1, 'email'), ticket2.id)
    assert_equal(2, NotificationFactory::Mailer.already_sent?(ticket2, @agent2, 'email'), ticket2.id)

    # create ticket in group
    ticket3 = Ticket.create!(
      title:         'some notification test - z preferences tests 3',
      group:         Group.lookup(name: 'TicketNotificationTest'),
      customer:      @customer,
      owner:         @agent2,
      state:         Ticket::State.lookup(name: 'new'),
      priority:      Ticket::Priority.lookup(name: '2 normal'),
      updated_by_id: @customer.id,
      created_by_id: @customer.id,
    )
    Ticket::Article.create!(
      ticket_id:     ticket3.id,
      from:          'some_sender@example.com',
      to:            'some_recipient@example.com',
      subject:       'some subject',
      message_id:    'some@id',
      body:          'some message',
      internal:      false,
      sender:        Ticket::Article::Sender.where(name: 'Customer').first,
      type:          Ticket::Article::Type.where(name: 'email').first,
      updated_by_id: @customer.id,
      created_by_id: @customer.id,
    )

    # execute object transaction
    TransactionDispatcher.commit
    Scheduler.worker(true)

    # verify notifications to @agent1 + @agent2
    assert_equal(0, NotificationFactory::Mailer.already_sent?(ticket3, @agent1, 'email'), ticket3.id)
    assert_equal(1, NotificationFactory::Mailer.already_sent?(ticket3, @agent2, 'email'), ticket3.id)

    # update ticket attributes
    ticket3.title    = "#{ticket3.title} - #2"
    ticket3.priority = Ticket::Priority.lookup(name: '3 high')
    ticket3.save!

    # execute object transaction
    TransactionDispatcher.commit
    Scheduler.worker(true)

    # verify notifications to @agent1 + @agent2
    assert_equal(0, NotificationFactory::Mailer.already_sent?(ticket3, @agent1, 'email'), ticket3.id)
    assert_equal(2, NotificationFactory::Mailer.already_sent?(ticket3, @agent2, 'email'), ticket3.id)

    @agent1.preferences['notification_config']['matrix']['create']['criteria']['owned_by_me'] = true
    @agent1.preferences['notification_config']['matrix']['create']['criteria']['owned_by_nobody'] = false
    @agent1.preferences['notification_config']['matrix']['create']['criteria']['no'] = true
    @agent1.preferences['notification_config']['matrix']['update']['criteria']['owned_by_me'] = true
    @agent1.preferences['notification_config']['matrix']['update']['criteria']['owned_by_nobody'] = false
    @agent1.preferences['notification_config']['matrix']['update']['criteria']['no'] = true
    @agent1.preferences['notification_config']['group_ids'] = [Group.lookup(name: 'TicketNotificationTest').id.to_s]
    @agent1.save!

    @agent2.preferences['notification_config']['matrix']['create']['criteria']['owned_by_me'] = false
    @agent2.preferences['notification_config']['matrix']['create']['criteria']['owned_by_nobody'] = false
    @agent2.preferences['notification_config']['matrix']['create']['criteria']['no'] = true
    @agent2.preferences['notification_config']['matrix']['update']['criteria']['owned_by_me'] = false
    @agent2.preferences['notification_config']['matrix']['update']['criteria']['owned_by_nobody'] = false
    @agent2.preferences['notification_config']['matrix']['update']['criteria']['no'] = true
    @agent1.preferences['notification_config']['group_ids'] = ['-']
    @agent2.save!

    travel 1.minute # to skip loopup cache in Transaction::Notification

    # create ticket in group
    ApplicationHandleInfo.current = 'scheduler.postmaster'
    ticket4 = Ticket.create!(
      title:         'some notification test - z preferences tests 4',
      group:         Group.lookup(name: 'TicketNotificationTest'),
      customer:      @customer,
      state:         Ticket::State.lookup(name: 'new'),
      priority:      Ticket::Priority.lookup(name: '2 normal'),
      updated_by_id: @customer.id,
      created_by_id: @customer.id,
    )
    Ticket::Article.create!(
      ticket_id:     ticket4.id,
      from:          'some_sender@example.com',
      to:            'some_recipient@example.com',
      subject:       'some subject',
      message_id:    'some@id',
      body:          'some message',
      internal:      false,
      sender:        Ticket::Article::Sender.where(name: 'Customer').first,
      type:          Ticket::Article::Type.where(name: 'email').first,
      updated_by_id: @customer.id,
      created_by_id: @customer.id,
    )

    # execute object transaction
    TransactionDispatcher.commit
    Scheduler.worker(true)

    # verify notifications to @agent1 + @agent2
    assert_equal(1, NotificationFactory::Mailer.already_sent?(ticket4, @agent1, 'email'), ticket4.id)
    assert_equal(1, NotificationFactory::Mailer.already_sent?(ticket4, @agent2, 'email'), ticket4.id)

    # update ticket attributes
    ticket4.title    = "#{ticket4.title} - #2"
    ticket4.priority = Ticket::Priority.lookup(name: '3 high')
    ticket4.save!

    # execute object transaction
    TransactionDispatcher.commit
    Scheduler.worker(true)

    # verify notifications to @agent1 + @agent2
    assert_equal(2, NotificationFactory::Mailer.already_sent?(ticket4, @agent1, 'email'), ticket4.id)
    assert_equal(2, NotificationFactory::Mailer.already_sent?(ticket4, @agent2, 'email'), ticket4.id)

    @agent1.preferences['notification_config']['matrix']['create']['criteria']['owned_by_me'] = true
    @agent1.preferences['notification_config']['matrix']['create']['criteria']['owned_by_nobody'] = false
    @agent1.preferences['notification_config']['matrix']['create']['criteria']['no'] = true
    @agent1.preferences['notification_config']['matrix']['update']['criteria']['owned_by_me'] = true
    @agent1.preferences['notification_config']['matrix']['update']['criteria']['owned_by_nobody'] = false
    @agent1.preferences['notification_config']['matrix']['update']['criteria']['no'] = true
    @agent1.preferences['notification_config']['group_ids'] = [Group.lookup(name: 'TicketNotificationTest').id.to_s]
    @agent1.save!

    @agent2.preferences['notification_config']['matrix']['create']['criteria']['owned_by_me'] = false
    @agent2.preferences['notification_config']['matrix']['create']['criteria']['owned_by_nobody'] = false
    @agent2.preferences['notification_config']['matrix']['create']['criteria']['no'] = true
    @agent2.preferences['notification_config']['matrix']['update']['criteria']['owned_by_me'] = false
    @agent2.preferences['notification_config']['matrix']['update']['criteria']['owned_by_nobody'] = false
    @agent2.preferences['notification_config']['matrix']['update']['criteria']['no'] = true
    @agent2.preferences['notification_config']['group_ids'] = [99]
    @agent2.save!

    travel 1.minute # to skip loopup cache in Transaction::Notification

    # create ticket in group
    ApplicationHandleInfo.current = 'scheduler.postmaster'
    ticket5 = Ticket.create!(
      title:         'some notification test - z preferences tests 5',
      group:         Group.lookup(name: 'TicketNotificationTest'),
      customer:      @customer,
      state:         Ticket::State.lookup(name: 'new'),
      priority:      Ticket::Priority.lookup(name: '2 normal'),
      updated_by_id: @customer.id,
      created_by_id: @customer.id,
    )
    Ticket::Article.create!(
      ticket_id:     ticket5.id,
      from:          'some_sender@example.com',
      to:            'some_recipient@example.com',
      subject:       'some subject',
      message_id:    'some@id',
      body:          'some message',
      internal:      false,
      sender:        Ticket::Article::Sender.where(name: 'Customer').first,
      type:          Ticket::Article::Type.where(name: 'email').first,
      updated_by_id: @customer.id,
      created_by_id: @customer.id,
    )

    # execute object transaction
    TransactionDispatcher.commit
    Scheduler.worker(true)

    # verify notifications to @agent1 + @agent2
    assert_equal(1, NotificationFactory::Mailer.already_sent?(ticket5, @agent1, 'email'), ticket5.id)
    assert_equal(0, NotificationFactory::Mailer.already_sent?(ticket5, @agent2, 'email'), ticket5.id)

    # update ticket attributes
    ticket5.title    = "#{ticket5.title} - #2"
    ticket5.priority = Ticket::Priority.lookup(name: '3 high')
    ticket5.save!

    # execute object transaction
    TransactionDispatcher.commit
    Scheduler.worker(true)

    # verify notifications to @agent1 + @agent2
    assert_equal(2, NotificationFactory::Mailer.already_sent?(ticket5, @agent1, 'email'), ticket5.id)
    assert_equal(0, NotificationFactory::Mailer.already_sent?(ticket5, @agent2, 'email'), ticket5.id)

    @agent1.preferences['notification_config']['matrix']['create']['criteria']['owned_by_me'] = true
    @agent1.preferences['notification_config']['matrix']['create']['criteria']['owned_by_nobody'] = false
    @agent1.preferences['notification_config']['matrix']['create']['criteria']['no'] = true
    @agent1.preferences['notification_config']['matrix']['update']['criteria']['owned_by_me'] = true
    @agent1.preferences['notification_config']['matrix']['update']['criteria']['owned_by_nobody'] = false
    @agent1.preferences['notification_config']['matrix']['update']['criteria']['no'] = true
    @agent1.preferences['notification_config']['group_ids'] = [999]
    @agent1.save!

    @agent2.preferences['notification_config']['matrix']['create']['criteria']['owned_by_me'] = true
    @agent2.preferences['notification_config']['matrix']['create']['criteria']['owned_by_nobody'] = false
    @agent2.preferences['notification_config']['matrix']['create']['criteria']['no'] = true
    @agent2.preferences['notification_config']['matrix']['update']['criteria']['owned_by_me'] = true
    @agent2.preferences['notification_config']['matrix']['update']['criteria']['owned_by_nobody'] = false
    @agent2.preferences['notification_config']['matrix']['update']['criteria']['no'] = true
    @agent2.preferences['notification_config']['group_ids'] = [999]
    @agent2.save!

    travel 1.minute # to skip loopup cache in Transaction::Notification

    # create ticket in group
    ApplicationHandleInfo.current = 'scheduler.postmaster'
    ticket6 = Ticket.create!(
      title:         'some notification test - z preferences tests 6',
      group:         Group.lookup(name: 'TicketNotificationTest'),
      customer:      @customer,
      owner:         @agent1,
      state:         Ticket::State.lookup(name: 'new'),
      priority:      Ticket::Priority.lookup(name: '2 normal'),
      updated_by_id: @customer.id,
      created_by_id: @customer.id,
    )
    Ticket::Article.create!(
      ticket_id:     ticket6.id,
      from:          'some_sender@example.com',
      to:            'some_recipient@example.com',
      subject:       'some subject',
      message_id:    'some@id',
      body:          'some message',
      internal:      false,
      sender:        Ticket::Article::Sender.where(name: 'Customer').first,
      type:          Ticket::Article::Type.where(name: 'email').first,
      updated_by_id: @customer.id,
      created_by_id: @customer.id,
    )

    # execute object transaction
    TransactionDispatcher.commit
    Scheduler.worker(true)

    # verify notifications to @agent1 + @agent2
    assert_equal(1, NotificationFactory::Mailer.already_sent?(ticket6, @agent1, 'email'), ticket6.id)
    assert_equal(1, NotificationFactory::Mailer.already_sent?(ticket6, @agent1, 'online'), ticket6.id)
    assert_equal(0, NotificationFactory::Mailer.already_sent?(ticket6, @agent2, 'email'), ticket6.id)
    assert_equal(0, NotificationFactory::Mailer.already_sent?(ticket6, @agent2, 'online'), ticket6.id)

    # update ticket attributes
    ticket6.title    = "#{ticket6.title} - #2"
    ticket6.priority = Ticket::Priority.lookup(name: '3 high')
    ticket6.save!

    # execute object transaction
    TransactionDispatcher.commit
    Scheduler.worker(true)

    # verify notifications to @agent1 + @agent2
    assert_equal(2, NotificationFactory::Mailer.already_sent?(ticket6, @agent1, 'email'), ticket6.id)
    assert_equal(2, NotificationFactory::Mailer.already_sent?(ticket6, @agent1, 'online'), ticket6.id)
    assert_equal(0, NotificationFactory::Mailer.already_sent?(ticket6, @agent2, 'email'), ticket6.id)
    assert_equal(0, NotificationFactory::Mailer.already_sent?(ticket6, @agent2, 'online'), ticket6.id)

    @agent1.preferences['notification_config']['matrix']['create']['criteria']['owned_by_me'] = true
    @agent1.preferences['notification_config']['matrix']['create']['criteria']['owned_by_nobody'] = false
    @agent1.preferences['notification_config']['matrix']['create']['criteria']['no'] = true
    @agent1.preferences['notification_config']['matrix']['create']['channel']['email'] = false
    @agent1.preferences['notification_config']['matrix']['create']['channel']['online'] = true
    @agent1.preferences['notification_config']['matrix']['update']['criteria']['owned_by_me'] = true
    @agent1.preferences['notification_config']['matrix']['update']['criteria']['owned_by_nobody'] = false
    @agent1.preferences['notification_config']['matrix']['update']['criteria']['no'] = true
    @agent1.preferences['notification_config']['matrix']['update']['channel']['email'] = false
    @agent1.preferences['notification_config']['matrix']['update']['channel']['online'] = true
    @agent1.preferences['notification_config']['group_ids'] = [999]
    @agent1.save!

    @agent2.preferences['notification_config']['matrix']['create']['criteria']['owned_by_me'] = true
    @agent2.preferences['notification_config']['matrix']['create']['criteria']['owned_by_nobody'] = false
    @agent2.preferences['notification_config']['matrix']['create']['criteria']['no'] = true
    @agent2.preferences['notification_config']['matrix']['create']['channel']['email'] = false
    @agent2.preferences['notification_config']['matrix']['create']['channel']['online'] = true
    @agent2.preferences['notification_config']['matrix']['update']['criteria']['owned_by_me'] = true
    @agent2.preferences['notification_config']['matrix']['update']['criteria']['owned_by_nobody'] = false
    @agent2.preferences['notification_config']['matrix']['update']['criteria']['no'] = true
    @agent2.preferences['notification_config']['matrix']['update']['channel']['email'] = false
    @agent2.preferences['notification_config']['matrix']['update']['channel']['online'] = true
    @agent2.preferences['notification_config']['group_ids'] = [999]
    @agent2.save!

    travel 1.minute # to skip loopup cache in Transaction::Notification

    # create ticket in group
    ApplicationHandleInfo.current = 'scheduler.postmaster'
    ticket7 = Ticket.create!(
      title:         'some notification test - z preferences tests 7',
      group:         Group.lookup(name: 'TicketNotificationTest'),
      customer:      @customer,
      owner:         @agent1,
      state:         Ticket::State.lookup(name: 'new'),
      priority:      Ticket::Priority.lookup(name: '2 normal'),
      updated_by_id: @customer.id,
      created_by_id: @customer.id,
    )
    Ticket::Article.create!(
      ticket_id:     ticket7.id,
      from:          'some_sender@example.com',
      to:            'some_recipient@example.com',
      subject:       'some subject',
      message_id:    'some@id',
      body:          'some message',
      internal:      false,
      sender:        Ticket::Article::Sender.where(name: 'Customer').first,
      type:          Ticket::Article::Type.where(name: 'email').first,
      updated_by_id: @customer.id,
      created_by_id: @customer.id,
    )

    # execute object transaction
    TransactionDispatcher.commit
    Scheduler.worker(true)

    # verify notifications to @agent1 + @agent2
    assert_equal(0, NotificationFactory::Mailer.already_sent?(ticket7, @agent1, 'email'), ticket7.id)
    assert_equal(1, NotificationFactory::Mailer.already_sent?(ticket7, @agent1, 'online'), ticket7.id)
    assert_equal(0, NotificationFactory::Mailer.already_sent?(ticket7, @agent2, 'email'), ticket7.id)
    assert_equal(0, NotificationFactory::Mailer.already_sent?(ticket7, @agent2, 'online'), ticket7.id)

    # update ticket attributes
    ticket7.title    = "#{ticket7.title} - #2"
    ticket7.priority = Ticket::Priority.lookup(name: '3 high')
    ticket7.save!

    # execute object transaction
    TransactionDispatcher.commit
    Scheduler.worker(true)

    # verify notifications to @agent1 + @agent2
    assert_equal(0, NotificationFactory::Mailer.already_sent?(ticket7, @agent1, 'email'), ticket7.id)
    assert_equal(2, NotificationFactory::Mailer.already_sent?(ticket7, @agent1, 'online'), ticket7.id)
    assert_equal(0, NotificationFactory::Mailer.already_sent?(ticket7, @agent2, 'email'), ticket7.id)
    assert_equal(0, NotificationFactory::Mailer.already_sent?(ticket7, @agent2, 'online'), ticket7.id)

  end

  test 'ticket notification events' do

    # create ticket in group
    ticket1 = Ticket.create!(
      title:         'some notification event test 1',
      group:         Group.lookup(name: 'TicketNotificationTest'),
      customer:      @customer,
      state:         Ticket::State.lookup(name: 'new'),
      priority:      Ticket::Priority.lookup(name: '2 normal'),
      updated_by_id: @customer.id,
      created_by_id: @customer.id,
    )
    Ticket::Article.create!(
      ticket_id:     ticket1.id,
      from:          'some_sender@example.com',
      to:            'some_recipient@example.com',
      subject:       'some subject',
      message_id:    'some@id',
      body:          'some message',
      internal:      false,
      sender:        Ticket::Article::Sender.where(name: 'Customer').first,
      type:          Ticket::Article::Type.where(name: 'email').first,
      updated_by_id: @customer.id,
      created_by_id: @customer.id,
    )
    assert(ticket1, 'ticket created')

    # execute object transaction
    TransactionDispatcher.commit

    # update ticket attributes
    ticket1.title    = "#{ticket1.title} - #2"
    ticket1.priority = Ticket::Priority.lookup(name: '3 high')
    ticket1.save!

    list         = EventBuffer.list('transaction')
    list_objects = TransactionDispatcher.get_uniq_changes(list)

    assert_equal('some notification event test 1', list_objects['Ticket'][ticket1.id][:changes]['title'][0])
    assert_equal('some notification event test 1 - #2', list_objects['Ticket'][ticket1.id][:changes]['title'][1])
    assert_not(list_objects['Ticket'][ticket1.id][:changes]['priority'])
    assert_equal(2, list_objects['Ticket'][ticket1.id][:changes]['priority_id'][0])
    assert_equal(3, list_objects['Ticket'][ticket1.id][:changes]['priority_id'][1])

    # update ticket attributes
    ticket1.title    = "#{ticket1.title} - #3"
    ticket1.priority = Ticket::Priority.lookup(name: '1 low')
    ticket1.save!

    list         = EventBuffer.list('transaction')
    list_objects = TransactionDispatcher.get_uniq_changes(list)

    assert_equal('some notification event test 1', list_objects['Ticket'][ticket1.id][:changes]['title'][0])
    assert_equal('some notification event test 1 - #2 - #3', list_objects['Ticket'][ticket1.id][:changes]['title'][1])
    assert_not(list_objects['Ticket'][ticket1.id][:changes]['priority'])
    assert_equal(2, list_objects['Ticket'][ticket1.id][:changes]['priority_id'][0])
    assert_equal(1, list_objects['Ticket'][ticket1.id][:changes]['priority_id'][1])

  end

  test 'ticket notification - out of office' do

    # create ticket in group
    ticket1 = Ticket.create!(
      title:         'some notification test out of office',
      group:         Group.lookup(name: 'TicketNotificationTest'),
      customer:      @customer,
      owner_id:      @agent2.id,
      #state: Ticket::State.lookup(name: 'new'),
      #priority: Ticket::Priority.lookup(name: '2 normal'),
      updated_by_id: @customer.id,
      created_by_id: @customer.id,
    )
    Ticket::Article.create!(
      ticket_id:     ticket1.id,
      from:          'some_sender@example.com',
      to:            'some_recipient@example.com',
      subject:       'some subject',
      message_id:    'some@id',
      body:          'some message',
      internal:      false,
      sender:        Ticket::Article::Sender.where(name: 'Customer').first,
      type:          Ticket::Article::Type.where(name: 'email').first,
      updated_by_id: @customer.id,
      created_by_id: @customer.id,
    )
    assert(ticket1, 'ticket created - ticket notification simple')

    # execute object transaction
    TransactionDispatcher.commit
    Scheduler.worker(true)

    # verify notifications to @agent1 + @agent2
    assert_equal(0, NotificationFactory::Mailer.already_sent?(ticket1, @agent1, 'email'), ticket1.id)
    assert_equal(1, NotificationFactory::Mailer.already_sent?(ticket1, @agent2, 'email'), ticket1.id)
    assert_equal(0, NotificationFactory::Mailer.already_sent?(ticket1, @agent3, 'email'), ticket1.id)
    assert_equal(0, NotificationFactory::Mailer.already_sent?(ticket1, @agent4, 'email'), ticket1.id)

    @agent2.out_of_office = true
    @agent2.preferences[:out_of_office_text] = 'at the doctor'
    @agent2.out_of_office_replacement_id = @agent3.id
    @agent2.out_of_office_start_at = Time.zone.today - 2.days
    @agent2.out_of_office_end_at = Time.zone.today + 2.days
    @agent2.save!

    # create ticket in group
    ticket2 = Ticket.create!(
      title:         'some notification test out of office',
      group:         Group.lookup(name: 'TicketNotificationTest'),
      customer:      @customer,
      owner_id:      @agent2.id,
      #state: Ticket::State.lookup(name: 'new'),
      #priority: Ticket::Priority.lookup(name: '2 normal'),
      updated_by_id: @customer.id,
      created_by_id: @customer.id,
    )
    Ticket::Article.create!(
      ticket_id:     ticket2.id,
      from:          'some_sender@example.com',
      to:            'some_recipient@example.com',
      subject:       'some subject',
      message_id:    'some@id',
      body:          'some message',
      internal:      false,
      sender:        Ticket::Article::Sender.where(name: 'Customer').first,
      type:          Ticket::Article::Type.where(name: 'email').first,
      updated_by_id: @customer.id,
      created_by_id: @customer.id,
    )
    assert(ticket2, 'ticket created - ticket notification simple')

    # execute object transaction
    TransactionDispatcher.commit
    Scheduler.worker(true)

    # verify notifications to @agent1 + @agent2
    assert_equal(0, NotificationFactory::Mailer.already_sent?(ticket2, @agent1, 'email'), ticket2.id)
    assert_equal(1, NotificationFactory::Mailer.already_sent?(ticket2, @agent2, 'email'), ticket2.id)
    assert_equal(1, NotificationFactory::Mailer.already_sent?(ticket2, @agent3, 'email'), ticket2.id)
    assert_equal(0, NotificationFactory::Mailer.already_sent?(ticket2, @agent4, 'email'), ticket2.id)

    # update ticket attributes
    ticket2.title    = "#{ticket2.title} - #2"
    ticket2.priority = Ticket::Priority.lookup(name: '3 high')
    ticket2.save!

    # execute object transaction
    TransactionDispatcher.commit
    Scheduler.worker(true)

    # verify notifications to @agent1 + @agent2
    assert_equal(0, NotificationFactory::Mailer.already_sent?(ticket2, @agent1, 'email'), ticket2.id)
    assert_equal(2, NotificationFactory::Mailer.already_sent?(ticket2, @agent2, 'email'), ticket2.id)
    assert_equal(2, NotificationFactory::Mailer.already_sent?(ticket2, @agent3, 'email'), ticket2.id)
    assert_equal(0, NotificationFactory::Mailer.already_sent?(ticket2, @agent4, 'email'), ticket2.id)

    @agent3.out_of_office = true
    @agent3.preferences[:out_of_office_text] = 'at the doctor'
    @agent3.out_of_office_replacement_id = @agent4.id
    @agent3.out_of_office_start_at = Time.zone.today - 2.days
    @agent3.out_of_office_end_at = Time.zone.today + 2.days
    @agent3.save!

    # update ticket attributes
    ticket2.title    = "#{ticket2.title} - #3"
    ticket2.priority = Ticket::Priority.lookup(name: '3 high')
    ticket2.save!

    # execute object transaction
    TransactionDispatcher.commit
    Scheduler.worker(true)

    # verify notifications to @agent1 + @agent2
    assert_equal(0, NotificationFactory::Mailer.already_sent?(ticket2, @agent1, 'email'), ticket2.id)
    assert_equal(3, NotificationFactory::Mailer.already_sent?(ticket2, @agent2, 'email'), ticket2.id)
    assert_equal(3, NotificationFactory::Mailer.already_sent?(ticket2, @agent3, 'email'), ticket2.id)
    assert_equal(1, NotificationFactory::Mailer.already_sent?(ticket2, @agent4, 'email'), ticket2.id)

  end

  test 'ticket notification template' do

    # create ticket in group
    ticket1 = Ticket.create!(
      title:         'some notification template test 1 Bobs\'s resumé',
      group:         Group.lookup(name: 'TicketNotificationTest'),
      customer:      @customer,
      state:         Ticket::State.lookup(name: 'new'),
      priority:      Ticket::Priority.lookup(name: '2 normal'),
      updated_by_id: @customer.id,
      created_by_id: @customer.id,
    )
    article = Ticket::Article.create!(
      ticket_id:     ticket1.id,
      from:          'some_sender@example.com',
      to:            'some_recipient@example.com',
      subject:       'some subject',
      message_id:    'some@id',
      body:          "some message\nnewline1 abc\nnewline2",
      internal:      false,
      sender:        Ticket::Article::Sender.where(name: 'Customer').first,
      type:          Ticket::Article::Type.where(name: 'email').first,
      updated_by_id: @customer.id,
      created_by_id: @customer.id,
    )
    assert(ticket1, 'ticket created - ticket notification template')

    bg = Transaction::Notification.new(
      ticket_id:  ticket1.id,
      article_id: article.id,
      type:       'update',
      changes:    {
        'priority_id'  => [1, 2],
        'pending_time' => [nil, Time.zone.parse('2015-01-11 23:33:47 UTC')],
      },
      user_id:    ticket1.updated_by_id,
    )

    # check changed attributes
    human_changes = bg.human_changes(@agent2, ticket1)
    assert(human_changes['Priority'], 'Check if attributes translated based on ObjectManager::Attribute')
    assert(human_changes['Pending till'], 'Check if attributes translated based on ObjectManager::Attribute')
    assert_equal('1 low', human_changes['Priority'][0])
    assert_equal('2 normal', human_changes['Priority'][1])
    assert_equal('', human_changes['Pending till'][0].to_s)
    assert_equal('2015-01-11 23:33:47 UTC', human_changes['Pending till'][1].to_s)
    assert_not(human_changes['priority_id'])
    assert_not(human_changes['pending_time'])
    assert_not(human_changes['pending_till'])

    # en notification
    result = NotificationFactory::Mailer.template(
      locale:   @agent2.preferences[:locale],
      timezone: @agent2.preferences[:timezone],
      template: 'ticket_update',
      objects:  {
        ticket:    ticket1,
        article:   article,
        recipient: @agent2,
        changes:   human_changes,
      },
    )
    assert_match(%r{Bobs's resumé}, result[:subject])
    assert_match(%r{Priority}, result[:body])
    assert_match(%r{1 low}, result[:body])
    assert_match(%r{2 normal}, result[:body])
    assert_match(%r{Pending till}, result[:body])
    assert_match('01/11/2015 19:33 (America/St_Lucia)', result[:body])
    assert_match(%r{update}, result[:body])
    assert_no_match(%r{pending_till}, result[:body])
    assert_no_match(%r{i18n}, result[:body])

    human_changes = bg.human_changes(@agent1, ticket1)
    assert(human_changes['Priority'], 'Check if attributes translated based on ObjectManager::Attribute')
    assert(human_changes['Pending till'], 'Check if attributes translated based on ObjectManager::Attribute')
    assert_equal('1 niedrig', human_changes['Priority'][0])
    assert_equal('2 normal', human_changes['Priority'][1])
    assert_equal('', human_changes['Pending till'][0].to_s)
    assert_equal('2015-01-11 23:33:47 UTC', human_changes['Pending till'][1].to_s)
    assert_not(human_changes['priority_id'])
    assert_not(human_changes['pending_time'])
    assert_not(human_changes['pending_till'])

    # de & Europe/Berlin notification
    result = NotificationFactory::Mailer.template(
      locale:   @agent1.preferences[:locale],
      timezone: @agent1.preferences[:timezone],
      template: 'ticket_update',
      objects:  {
        ticket:    ticket1,
        article:   article,
        recipient: @agent1,
        changes:   human_changes,
      },
    )

    assert_match(%r{Bobs's resumé}, result[:subject])
    assert_match(%r{Priorität}, result[:body])
    assert_match(%r{1 niedrig}, result[:body])
    assert_match(%r{2 normal}, result[:body])
    assert_match(%r{Warten}, result[:body])
    assert_match('12.01.2015 00:33 (Europe/Berlin)', result[:body])
    assert_match(%r{aktualis}, result[:body])
    assert_no_match(%r{pending_till}, result[:body])
    assert_no_match(%r{i18n}, result[:body])

    bg = Transaction::Notification.new(
      ticket_id:  ticket1.id,
      article_id: article.id,
      type:       'update',
      changes:    {
        title:       ['some notification template test old 1', 'some notification template test 1 #2'],
        priority_id: [2, 3],
      },
      user_id:    @customer.id,
    )

    # check changed attributes
    human_changes = bg.human_changes(@agent1, ticket1)
    assert(human_changes['Title'], 'Check if attributes translated based on ObjectManager::Attribute')
    assert(human_changes['Priority'], 'Check if attributes translated based on ObjectManager::Attribute')
    assert_equal('2 normal', human_changes['Priority'][0])
    assert_equal('3 hoch', human_changes['Priority'][1])
    assert_equal('some notification template test old 1', human_changes['Title'][0])
    assert_equal('some notification template test 1 #2', human_changes['Title'][1])
    assert_not(human_changes['priority_id'])
    assert_not(human_changes['pending_time'])
    assert_not(human_changes['pending_till'])

    # de notification
    result = NotificationFactory::Mailer.template(
      locale:   @agent1.preferences[:locale],
      timezone: @agent1.preferences[:timezone],
      template: 'ticket_update',
      objects:  {
        ticket:    ticket1,
        article:   article,
        recipient: @agent1,
        changes:   human_changes,
      }
    )

    assert_match(%r{Bobs's resumé}, result[:subject])
    assert_match(%r{Titel}, result[:body])
    assert_no_match(%r{Title}, result[:body])
    assert_match(%r{some notification template test old 1}, result[:body])
    assert_match(%r{some notification template test 1 #2}, result[:body])
    assert_match(%r{Priorität}, result[:body])
    assert_no_match(%r{Priority}, result[:body])
    assert_match(%r{3 hoch}, result[:body])
    assert_match(%r{2 normal}, result[:body])
    assert_match(%r{aktualisier}, result[:body])

    human_changes = bg.human_changes(@agent2, ticket1)

    # en notification
    result = NotificationFactory::Mailer.template(
      locale:   @agent2.preferences[:locale],
      timezone: @agent2.preferences[:timezone],
      template: 'ticket_update',
      objects:  {
        ticket:    ticket1,
        article:   article,
        recipient: @agent2,
        changes:   human_changes,
      }
    )

    assert_match(%r{Bobs's resumé}, result[:subject])
    assert_match(%r{Title}, result[:body])
    assert_match(%r{some notification template test old 1}, result[:body])
    assert_match(%r{some notification template test 1 #2}, result[:body])
    assert_match(%r{Priority}, result[:body])
    assert_match(%r{3 high}, result[:body])
    assert_match(%r{2 normal}, result[:body])
    assert_no_match(%r{Pending till}, result[:body])
    assert_no_match(%r{2015-01-11 23:33:47 UTC}, result[:body])
    assert_match(%r{update}, result[:body])
    assert_no_match(%r{pending_till}, result[:body])
    assert_no_match(%r{i18n}, result[:body])

    # en notification
    ticket1.escalation_at = Time.zone.parse('2019-04-01T10:00:00Z')
    result = NotificationFactory::Mailer.template(
      locale:   @agent2.preferences[:locale],
      timezone: @agent2.preferences[:timezone],
      template: 'ticket_escalation',
      objects:  {
        ticket:    ticket1,
        article:   article,
        recipient: @agent2,
      }
    )

    assert_match('Ticket is escalated (some notification template test 1 Bobs\'s resumé', result[:subject])
    assert_match('is escalated since "04/01/2019 06:00 (America/St_Lucia)"!', result[:body])

  end

end
