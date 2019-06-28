require 'test_helper'

class TicketTriggerExtendedRecursiveDisabledTest < ActiveSupport::TestCase

  setup do
    Setting.set('ticket_trigger_recursive', false)
  end

  test 'recursive trigger' do
    Trigger.create!(
      name:                 '1) set prio to 3 high',
      condition:            {
        'ticket.action'   => {
          'operator' => 'is',
          'value'    => 'create',
        },
        'ticket.state_id' => {
          'operator' => 'is',
          'value'    => Ticket::State.lookup(name: 'new').id.to_s,
        },
      },
      perform:              {
        'ticket.priority_id' => {
          'value' => Ticket::Priority.lookup(name: '3 high').id.to_s,
        },
      },
      disable_notification: true,
      active:               true,
      created_by_id:        1,
      updated_by_id:        1,
    )

    Trigger.create!(
      name:                 '2) set state to closed',
      condition:            {
        'ticket.action'      => {
          'operator' => 'is',
          'value'    => 'create',
        },
        'ticket.priority_id' => {
          'operator' => 'is',
          'value'    => Ticket::Priority.lookup(name: '3 high').id.to_s,
        },
      },
      perform:              {
        'ticket.state_id' => {
          'value' => Ticket::State.lookup(name: 'closed').id.to_s,
        },
      },
      disable_notification: true,
      active:               true,
      created_by_id:        1,
      updated_by_id:        1,
    )

    email_raw_string = 'From: me@example.com
To: customer@example.com
Subject: some new subject

Some Text'

    ticket_p, _article_p, _user_p, _mail = Channel::EmailParser.new.process({}, email_raw_string)
    assert_equal('some new subject', ticket_p.title)
    assert_equal('Users', ticket_p.group.name)
    assert_equal('3 high', ticket_p.priority.name)
    assert_equal('closed', ticket_p.state.name)

    assert_equal(1, ticket_p.articles.count, 'ticket1.articles verify')
  end

  test 'recursive trigger - loop test' do
    Trigger.create!(
      name:                 '1) set prio to 3 high',
      condition:            {
        'ticket.priority_id' => {
          'operator' => 'is',
          'value'    => Ticket::Priority.lookup(name: '2 normal').id.to_s,
        },
      },
      perform:              {
        'ticket.priority_id' => {
          'value' => Ticket::Priority.lookup(name: '3 high').id.to_s,
        },
        'ticket.state_id'    => {
          'value' => Ticket::State.lookup(name: 'closed').id.to_s,
        },
      },
      disable_notification: true,
      active:               true,
      created_by_id:        1,
      updated_by_id:        1,
    )

    Trigger.create!(
      name:                 '2) set prio to 1 low',
      condition:            {
        'ticket.priority_id' => {
          'operator' => 'is',
          'value'    => Ticket::Priority.lookup(name: '3 high').id.to_s,
        },
      },
      perform:              {
        'ticket.priority_id' => {
          'value' => Ticket::Priority.lookup(name: '1 low').id.to_s,
        },
        'ticket.state_id'    => {
          'value' => Ticket::State.lookup(name: 'open').id.to_s,
        },
      },
      disable_notification: true,
      active:               true,
      created_by_id:        1,
      updated_by_id:        1,
    )

    Trigger.create!(
      name:                 '3) set prio to 3 high',
      condition:            {
        'ticket.priority_id' => {
          'operator' => 'is',
          'value'    => Ticket::Priority.lookup(name: '1 low').id.to_s,
        },
      },
      perform:              {
        'ticket.priority_id' => {
          'value' => Ticket::Priority.lookup(name: '2 normal').id.to_s,
        },
      },
      disable_notification: true,
      active:               true,
      created_by_id:        1,
      updated_by_id:        1,
    )

    email_raw_string = 'From: me@example.com
To: customer@example.com
Subject: some new subject

Some Text'

    ticket_p, _article_p, _user_p, _mail = Channel::EmailParser.new.process({}, email_raw_string)
    assert_equal('some new subject', ticket_p.title)
    assert_equal('Users', ticket_p.group.name)
    assert_equal('2 normal', ticket_p.priority.name)
    assert_equal('open', ticket_p.state.name)

    assert_equal(1, ticket_p.articles.count, 'ticket1.articles verify')
  end

  test 'recursive trigger - 2 trigger will not trigger next trigger' do
    Trigger.create!(
      name:                 '1) set prio to 3 high',
      condition:            {
        'ticket.action'      => {
          'operator' => 'is',
          'value'    => 'create',
        },
        'ticket.priority_id' => {
          'operator' => 'is',
          'value'    => Ticket::Priority.lookup(name: '2 normal').id.to_s,
        },
      },
      perform:              {
        'ticket.priority_id' => {
          'value' => Ticket::Priority.lookup(name: '3 high').id.to_s,
        },
      },
      disable_notification: true,
      active:               true,
      created_by_id:        1,
      updated_by_id:        1,
    )

    Trigger.create!(
      name:                 '2) set state to open',
      condition:            {
        'ticket.action'      => {
          'operator' => 'is',
          'value'    => 'create',
        },
        'ticket.priority_id' => {
          'operator' => 'is',
          'value'    => Ticket::Priority.lookup(name: '2 normal').id.to_s,
        },
      },
      perform:              {
        'ticket.state_id' => {
          'value' => Ticket::State.lookup(name: 'open').id.to_s,
        },
      },
      disable_notification: true,
      active:               true,
      created_by_id:        1,
      updated_by_id:        1,
    )

    Trigger.create!(
      name:                 '3) set state to closed',
      condition:            {
        'ticket.action'      => {
          'operator' => 'is',
          'value'    => 'create',
        },
        'ticket.priority_id' => {
          'operator' => 'is',
          'value'    => Ticket::Priority.lookup(name: '2 normal').id.to_s,
        },
        'ticket.state_id'    => {
          'operator' => 'is',
          'value'    => Ticket::State.lookup(name: 'open').id.to_s,
        },
      },
      perform:              {
        'ticket.state_id' => {
          'value' => Ticket::State.lookup(name: 'closed').id.to_s,
        },
      },
      disable_notification: true,
      active:               true,
      created_by_id:        1,
      updated_by_id:        1,
    )

    email_raw_string = 'From: me@example.com
To: customer@example.com
Subject: some new subject

Some Text'

    ticket_p, _article_p, _user_p, _mail = Channel::EmailParser.new.process({}, email_raw_string)
    assert_equal('some new subject', ticket_p.title)
    assert_equal('Users', ticket_p.group.name)
    assert_equal('3 high', ticket_p.priority.name)
    assert_equal('new', ticket_p.state.name)

    assert_equal(1, ticket_p.articles.count, 'ticket1.articles verify')

  end

  test 'recursive trigger - 2 trigger will trigger next trigger - case 1' do
    Trigger.create!(
      name:                 '1) set state to closed',
      condition:            {
        'ticket.action'      => {
          'operator' => 'is',
          'value'    => 'create',
        },
        'ticket.priority_id' => {
          'operator' => 'is',
          'value'    => Ticket::Priority.lookup(name: '3 high').id.to_s,
        },
        'ticket.state_id'    => {
          'operator' => 'is',
          'value'    => Ticket::State.lookup(name: 'open').id.to_s,
        },
      },
      perform:              {
        'ticket.state_id' => {
          'value' => Ticket::State.lookup(name: 'closed').id.to_s,
        },
      },
      disable_notification: true,
      active:               true,
      created_by_id:        1,
      updated_by_id:        1,
    )

    Trigger.create!(
      name:                 '2) set prio to 3 high',
      condition:            {
        'ticket.action'      => {
          'operator' => 'is',
          'value'    => 'create',
        },
        'ticket.priority_id' => {
          'operator' => 'is',
          'value'    => Ticket::Priority.lookup(name: '2 normal').id.to_s,
        },
      },
      perform:              {
        'ticket.priority_id' => {
          'value' => Ticket::Priority.lookup(name: '3 high').id.to_s,
        },
      },
      disable_notification: true,
      active:               true,
      created_by_id:        1,
      updated_by_id:        1,
    )

    Trigger.create!(
      name:                 '3) set state to open',
      condition:            {
        'ticket.action' => {
          'operator' => 'is',
          'value'    => 'create',
        },
      },
      perform:              {
        'ticket.state_id' => {
          'value' => Ticket::State.lookup(name: 'open').id.to_s,
        },
      },
      disable_notification: true,
      active:               true,
      created_by_id:        1,
      updated_by_id:        1,
    )

    email_raw_string = 'From: me@example.com
To: customer@example.com
Subject: some new subject

Some Text'

    ticket_p, _article_p, _user_p, _mail = Channel::EmailParser.new.process({}, email_raw_string)

    assert_equal('some new subject', ticket_p.title)
    assert_equal('Users', ticket_p.group.name)
    assert_equal('3 high', ticket_p.priority.name)
    assert_equal('open', ticket_p.state.name)
    assert_equal(1, ticket_p.articles.count, 'ticket1.articles verify')

  end

  test 'recursive trigger - 2 trigger will trigger next trigger - case 2' do
    Trigger.create!(
      name:                 '1) set prio to 3 high',
      condition:            {
        'ticket.action'      => {
          'operator' => 'is',
          'value'    => 'create',
        },
        'ticket.priority_id' => {
          'operator' => 'is',
          'value'    => Ticket::Priority.lookup(name: '2 normal').id.to_s,
        },
        'ticket.state_id'    => {
          'operator' => 'is',
          'value'    => Ticket::State.lookup(name: 'closed').id.to_s,
        },
      },
      perform:              {
        'ticket.priority_id' => {
          'value' => Ticket::Priority.lookup(name: '3 high').id.to_s,
        },
      },
      disable_notification: true,
      active:               true,
      created_by_id:        1,
      updated_by_id:        1,
    )

    Trigger.create!(
      name:                 '2) set state to closed',
      condition:            {
        'ticket.action'      => {
          'operator' => 'is',
          'value'    => 'create',
        },
        'ticket.priority_id' => {
          'operator' => 'is',
          'value'    => Ticket::Priority.lookup(name: '2 normal').id.to_s,
        },
        'ticket.state_id'    => {
          'operator' => 'is',
          'value'    => Ticket::State.lookup(name: 'open').id.to_s,
        },
      },
      perform:              {
        'ticket.state_id' => {
          'value' => Ticket::State.lookup(name: 'closed').id.to_s,
        },
      },
      disable_notification: true,
      active:               true,
      created_by_id:        1,
      updated_by_id:        1,
    )

    Trigger.create!(
      name:                 '3) set state to open',
      condition:            {
        'ticket.action' => {
          'operator' => 'is',
          'value'    => 'create',
        },
      },
      perform:              {
        'ticket.state_id' => {
          'value' => Ticket::State.lookup(name: 'open').id.to_s,
        },
      },
      disable_notification: true,
      active:               true,
      created_by_id:        1,
      updated_by_id:        1,
    )

    email_raw_string = 'From: me@example.com
To: customer@example.com
Subject: some new subject

Some Text'

    ticket_p, _article_p, _user_p, _mail = Channel::EmailParser.new.process({}, email_raw_string)

    assert_equal('some new subject', ticket_p.title)
    assert_equal('Users', ticket_p.group.name)
    assert_equal('2 normal', ticket_p.priority.name)
    assert_equal('open', ticket_p.state.name)

    assert_equal(1, ticket_p.articles.count, 'ticket1.articles verify')

  end

  test 'trigger based move and verify correct agent notifications' do

    group1 = Group.create!(
      name:          'Group 1',
      active:        true,
      email_address: EmailAddress.first,
      created_by_id: 1,
      updated_by_id: 1,
    )
    group2 = Group.create!(
      name:          'Group 2',
      active:        true,
      email_address: EmailAddress.first,
      created_by_id: 1,
      updated_by_id: 1,
    )
    group3 = Group.create!(
      name:          'Group 3',
      active:        true,
      email_address: EmailAddress.first,
      created_by_id: 1,
      updated_by_id: 1,
    )
    roles = Role.where(name: 'Agent')
    user1 = User.create!(
      login:         'trigger1@example.org',
      firstname:     'trigger1',
      lastname:      'trigger1',
      email:         'trigger1@example.org',
      password:      'some_pass',
      active:        true,
      groups:        [group1],
      roles:         roles,
      created_by_id: 1,
      updated_by_id: 1,
    )
    user2 = User.create!(
      login:         'trigger2@example.org',
      firstname:     'trigger2',
      lastname:      'trigger2',
      email:         'trigger2@example.org',
      password:      'some_pass',
      active:        true,
      groups:        [group2],
      roles:         roles,
      created_by_id: 1,
      updated_by_id: 1,
    )

    # trigger, move ticket created in group1 into group3 and then into group2
    Trigger.create_or_update(
      name:                 '1 dispatch',
      condition:            {
        'ticket.action'   => {
          'operator' => 'is',
          'value'    => 'create',
        },
        'ticket.group_id' => {
          'operator' => 'is',
          'value'    => group3.id.to_s,
        },
        'ticket.state_id' => {
          'operator' => 'is',
          'value'    => Ticket::State.lookup(name: 'new').id.to_s,
        },
      },
      perform:              {
        'ticket.group_id' => {
          'value' => group2.id.to_s,
        },
      },
      disable_notification: true,
      active:               true,
      created_by_id:        1,
      updated_by_id:        1,
    )
    Trigger.create_or_update(
      name:                 '2 dispatch',
      condition:            {
        'ticket.action'   => {
          'operator' => 'is',
          'value'    => 'create',
        },
        'ticket.state_id' => {
          'operator' => 'is',
          'value'    => Ticket::State.lookup(name: 'new').id.to_s,
        },
      },
      perform:              {
        'ticket.group_id' => {
          'value' => group3.id.to_s,
        },
      },
      disable_notification: true,
      active:               true,
      created_by_id:        1,
      updated_by_id:        1,
    )

    ticket1 = Ticket.create!(
      title:         '123',
      group:         group1,
      customer_id:   2,
      state:         Ticket::State.lookup(name: 'new'),
      priority:      Ticket::Priority.lookup(name: '2 normal'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert(ticket1)

    assert_equal(ticket1.title, '123')
    assert_equal(ticket1.group.name, group1.name)
    assert_equal(ticket1.state.name, 'new')

    Ticket::Article.create!(
      ticket_id:     ticket1.id,
      from:          'some_sender@example.com',
      to:            'some_recipient@example.com',
      subject:       'some subject',
      message_id:    'some@id',
      body:          'some message',
      internal:      false,
      sender:        Ticket::Article::Sender.find_by(name: 'Customer'),
      type:          Ticket::Article::Type.find_by(name: 'email'),
      updated_by_id: 1,
      created_by_id: 1,
    )

    # verfiy if agent1 got no notifcation
    assert_equal(0, NotificationFactory::Mailer.already_sent?(ticket1, user1, 'email'), ticket1.id)

    # verfiy if agent2 got no notifcation
    assert_equal(0, NotificationFactory::Mailer.already_sent?(ticket1, user2, 'email'), ticket1.id)

    Observer::Transaction.commit
    Scheduler.worker(true)

    ticket1.reload
    assert_equal('123', ticket1.title)
    assert_equal(group3.name, ticket1.group.name)
    assert_equal('new', ticket1.state.name)
    assert_equal('2 normal', ticket1.priority.name)
    assert_equal(1, ticket1.articles.count)

    # verfiy if agent1 got no notifcation
    assert_equal(0, NotificationFactory::Mailer.already_sent?(ticket1, user1, 'email'), ticket1.id)

    # verfiy if agent2 got notifcation
    assert_equal(0, NotificationFactory::Mailer.already_sent?(ticket1, user2, 'email'), ticket1.id)

  end

  test 'recursive trigger loop check' do
    Trigger.create!(
      name:                 '000',
      condition:            {
        'ticket.action'      => {
          'operator' => 'is',
          'value'    => 'create',
        },
        'ticket.priority_id' => {
          'operator' => 'is',
          'value'    => Ticket::Priority.lookup(name: '1 low').id.to_s,
        },
      },
      perform:              {
        'ticket.state_id' => {
          'value' => Ticket::State.lookup(name: 'closed').id.to_s,
        },
      },
      disable_notification: true,
      active:               true,
      created_by_id:        1,
      updated_by_id:        1,
    )
    Trigger.create!(
      name:                 '001',
      condition:            {
        'ticket.action'      => {
          'operator' => 'is',
          'value'    => 'create',
        },
        'ticket.priority_id' => {
          'operator' => 'is',
          'value'    => Ticket::Priority.lookup(name: '3 high').id.to_s,
        },
      },
      perform:              {
        'ticket.priority_id' => {
          'value' => Ticket::Priority.lookup(name: '1 low').id.to_s,
        },
      },
      disable_notification: true,
      active:               true,
      created_by_id:        1,
      updated_by_id:        1,
    )
    Trigger.create!(
      name:                 '002',
      condition:            {
        'ticket.action'      => {
          'operator' => 'is',
          'value'    => 'create',
        },
        'ticket.priority_id' => {
          'operator' => 'is',
          'value'    => Ticket::Priority.lookup(name: '2 normal').id.to_s,
        },
      },
      perform:              {
        'ticket.priority_id' => {
          'value' => Ticket::Priority.lookup(name: '3 high').id.to_s,
        },
      },
      disable_notification: true,
      active:               true,
      created_by_id:        1,
      updated_by_id:        1,
    )
    group1 = Group.find_by(name: 'Users')
    ticket1 = Ticket.create!(
      title:         '123',
      group:         group1,
      customer_id:   2,
      state:         Ticket::State.lookup(name: 'new'),
      priority:      Ticket::Priority.lookup(name: '2 normal'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert(ticket1)

    assert_equal(ticket1.title, '123')
    assert_equal(ticket1.group.name, group1.name)
    assert_equal(ticket1.state.name, 'new')

    Ticket::Article.create!(
      ticket_id:     ticket1.id,
      from:          'some_sender@example.com',
      to:            'some_recipient@example.com',
      subject:       'some subject',
      message_id:    'some@id',
      body:          'some message',
      internal:      false,
      sender:        Ticket::Article::Sender.find_by(name: 'Customer'),
      type:          Ticket::Article::Type.find_by(name: 'email'),
      updated_by_id: 1,
      created_by_id: 1,
    )

    Observer::Transaction.commit
    Scheduler.worker(true)

    ticket1.reload
    assert_equal('123', ticket1.title)
    assert_equal('new', ticket1.state.name)
    assert_equal('3 high', ticket1.priority.name)
    assert_equal(1, ticket1.articles.count)

  end

end
