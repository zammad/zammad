# rubocop:disable all
require 'test_helper'

class EmailPostmasterTest < ActiveSupport::TestCase
  test 'valid/invalid postmaster filter' do
    PostmasterFilter.create!(
      name: 'not used',
      match: {
        from: {
          operator: 'contains',
          value: 'nobody@example.com',
        },
      },
      perform: {
        'X-Zammad-Ticket-priority' => {
          value: '3 high',
        },
      },
      channel: 'email',
      active: true,
      created_by_id: 1,
      updated_by_id: 1,
    )
    assert_raises(Exceptions::UnprocessableEntity) {
      PostmasterFilter.create!(
        name: 'empty filter should not work',
        match: {},
        perform: {
          'X-Zammad-Ticket-priority' => {
            value: '3 high',
          },
        },
        channel: 'email',
        active: true,
        created_by_id: 1,
        updated_by_id: 1,
      )
    }
    assert_raises(Exceptions::UnprocessableEntity) {
      PostmasterFilter.create!(
        name: 'empty filter should not work',
        match: {
          from: {
            operator: 'contains',
            value: '',
          },
        },
        perform: {
          'X-Zammad-Ticket-priority' => {
            value: '3 high',
          },
        },
        channel: 'email',
        active: true,
        created_by_id: 1,
        updated_by_id: 1,
      )
    }
    assert_raises(Exceptions::UnprocessableEntity) {
      PostmasterFilter.create!(
        name: 'invalid regex',
        match: {
          from: {
            operator: 'contains',
            value: 'regex:[]',
          },
        },
        perform: {
          'X-Zammad-Ticket-priority' => {
            value: '3 high',
          },
        },
        channel: 'email',
        active: true,
        created_by_id: 1,
        updated_by_id: 1,
      )
    }
    assert_raises(Exceptions::UnprocessableEntity) {
      PostmasterFilter.create!(
        name: 'invalid regex',
        match: {
          from: {
            operator: 'contains',
            value: 'regex:??',
          },
        },
        perform: {
          'X-Zammad-Ticket-priority' => {
            value: '3 high',
          },
        },
        channel: 'email',
        active: true,
        created_by_id: 1,
        updated_by_id: 1,
      )
    }
    assert_raises(Exceptions::UnprocessableEntity) {
      PostmasterFilter.create!(
        name: 'invalid regex',
        match: {
          from: {
            operator: 'contains',
            value: 'regex:*',
          },
        },
        perform: {
          'X-Zammad-Ticket-priority' => {
            value: '3 high',
          },
        },
        channel: 'email',
        active: true,
        created_by_id: 1,
        updated_by_id: 1,
      )
    }
    PostmasterFilter.create!(
      name: 'use .*',
      match: {
        from: {
          operator: 'contains',
          value: '*',
        },
      },
      perform: {
        'X-Zammad-Ticket-priority' => {
          value: '3 high',
        },
      },
      channel: 'email',
      active: true,
      created_by_id: 1,
      updated_by_id: 1,
    )
  end

  test 'process with postmaster filter with regex' do
    group_default = Group.lookup(name: 'Users')
    group1 = Group.create_if_not_exists(
      name: 'Test Group1',
      created_by_id: 1,
      updated_by_id: 1,
    )
    group2 = Group.create_if_not_exists(
      name: 'Test Group2',
      created_by_id: 1,
      updated_by_id: 1,
    )

    PostmasterFilter.destroy_all
    PostmasterFilter.create!(
      name: 'used - empty selector',
      match: {
        from: {
          operator: 'contains',
          value: 'regex:.*',
        },
      },
      perform: {
        'X-Zammad-Ticket-group_id' => {
          value: group2.id,
        },
        'X-Zammad-Ticket-priority_id' => {
          value: '1',
        },
        'x-Zammad-Article-Internal' => {
          value: true,
        },
      },
      channel: 'email',
      active: true,
      created_by_id: 1,
      updated_by_id: 1,
    )

    data = 'From: Some Body <somebody@example.com>
To: Bob <bod@example.com>
Cc: any@example.com
Subject: some subject - no selector

Some Text'

    parser = Channel::EmailParser.new
    ticket, article, user = parser.process({ group_id: group_default.id, trusted: false }, data)

    assert_equal('Test Group2', ticket.group.name)
    assert_equal('1 low', ticket.priority.name)
    assert_equal('some subject - no selector', ticket.title)

    assert_equal('Customer', article.sender.name)
    assert_equal('email', article.type.name)
    assert_equal(true, article.internal)

    PostmasterFilter.destroy_all
    PostmasterFilter.create!(
      name: 'used - empty selector',
      match: {
        from: {
          operator: 'contains',
          value: '*',
        },
      },
      perform: {
        'X-Zammad-Ticket-group_id' => {
          value: group2.id,
        },
        'X-Zammad-Ticket-priority_id' => {
          value: '1',
        },
        'x-Zammad-Article-Internal' => {
          value: true,
        },
      },
      channel: 'email',
      active: true,
      created_by_id: 1,
      updated_by_id: 1,
    )

    data = 'From: Some Body <somebody@example.com>
To: Bob <bod@example.com>
Cc: any@example.com
Subject: some subject - no selector

Some Text'

    parser = Channel::EmailParser.new
    ticket, article, user = parser.process({ group_id: group_default.id, trusted: false }, data)

    assert_equal('Test Group2', ticket.group.name)
    assert_equal('1 low', ticket.priority.name)
    assert_equal('some subject - no selector', ticket.title)

    assert_equal('Customer', article.sender.name)
    assert_equal('email', article.type.name)
    assert_equal(true, article.internal)

    PostmasterFilter.destroy_all
    PostmasterFilter.create!(
      name: 'used - empty selector',
      match: {
        subject: {
          operator: 'contains',
          value: '*me*',
        },
      },
      perform: {
        'X-Zammad-Ticket-group_id' => {
          value: group2.id,
        },
        'X-Zammad-Ticket-priority_id' => {
          value: '1',
        },
        'x-Zammad-Article-Internal' => {
          value: true,
        },
      },
      channel: 'email',
      active: true,
      created_by_id: 1,
      updated_by_id: 1,
    )

    data = 'From: Some Body <somebody@example.com>
To: Bob <bod@example.com>
Cc: any@example.com
Subject: *me*

Some Text'

    parser = Channel::EmailParser.new
    ticket, article, user = parser.process({ group_id: group_default.id, trusted: false }, data)

    assert_equal('Test Group2', ticket.group.name)
    assert_equal('1 low', ticket.priority.name)
    assert_equal('*me*', ticket.title)

    assert_equal('Customer', article.sender.name)
    assert_equal('email', article.type.name)
    assert_equal(true, article.internal)

    PostmasterFilter.destroy_all
    PostmasterFilter.create!(
      name: 'used - empty selector',
      match: {
        subject: {
          operator: 'contains not',
          value: '*me*',
        },
      },
      perform: {
        'X-Zammad-Ticket-group_id' => {
          value: group2.id,
        },
        'X-Zammad-Ticket-priority_id' => {
          value: '1',
        },
        'x-Zammad-Article-Internal' => {
          value: true,
        },
      },
      channel: 'email',
      active: true,
      created_by_id: 1,
      updated_by_id: 1,
    )

    data = 'From: Some Body <somebody@example.com>
To: Bob <bod@example.com>
Cc: any@example.com
Subject: *mo*

Some Text'

    parser = Channel::EmailParser.new
    ticket, article, user = parser.process({ group_id: group_default.id, trusted: false }, data)

    assert_equal('Test Group2', ticket.group.name)
    assert_equal('1 low', ticket.priority.name)
    assert_equal('*mo*', ticket.title)

    assert_equal('Customer', article.sender.name)
    assert_equal('email', article.type.name)
    assert_equal(true, article.internal)

    PostmasterFilter.destroy_all
    PostmasterFilter.create!(
      name: 'used - empty selector',
      match: {
        subject: {
          operator: 'contains not',
          value: '*me*',
        },
      },
      perform: {
        'X-Zammad-Ticket-group_id' => {
          value: group2.id,
        },
        'X-Zammad-Ticket-priority_id' => {
          value: '1',
        },
        'x-Zammad-Article-Internal' => {
          value: true,
        },
      },
      channel: 'email',
      active: true,
      created_by_id: 1,
      updated_by_id: 1,
    )

    data = 'From: Some Body <somebody@example.com>
To: Bob <bod@example.com>
Cc: any@example.com
Subject: *me*

Some Text'

    parser = Channel::EmailParser.new
    ticket, article, user = parser.process({ group_id: group_default.id, trusted: false }, data)

    assert_equal('Users', ticket.group.name)
    assert_equal('2 normal', ticket.priority.name)
    assert_equal('*me*', ticket.title)

    assert_equal('Customer', article.sender.name)
    assert_equal('email', article.type.name)
    assert_equal(false, article.internal)
  end

  test 'process with postmaster filter - message-id as match condition' do
    PostmasterFilter.create!(
      name: 'used - message-id',
      match: {
        'message-id': {
          operator: 'contains',
          value: '@sombody.domain>',
        },
      },
      perform: {
        'X-Zammad-Ticket-priority_id' => {
          value: '1',
        },
        'x-Zammad-Article-Internal' => {
          value: true,
        },
      },
      channel: 'email',
      active: true,
      created_by_id: 1,
      updated_by_id: 1,
    )

    data = 'From: Some Body <somebody@example.com>
To: Bob <bod@example.com>
Cc: any@example.com
Subject: *me*
Message-Id: <1520781034.17887@sombody.domain>

Some Text'

    parser = Channel::EmailParser.new
    ticket, article, user = parser.process({}, data)

    assert_equal('Users', ticket.group.name)
    assert_equal('1 low', ticket.priority.name)
    assert_equal('*me*', ticket.title)

    assert_equal('Customer', article.sender.name)
    assert_equal('email', article.type.name)
    assert_equal(true, article.internal)
  end

  test 'process with postmaster filter' do
    group_default = Group.lookup(name: 'Users')
    group1 = Group.create_if_not_exists(
      name: 'Test Group1',
      created_by_id: 1,
      updated_by_id: 1,
    )
    group2 = Group.create_if_not_exists(
      name: 'Test Group2',
      created_by_id: 1,
      updated_by_id: 1,
    )
    PostmasterFilter.destroy_all
    PostmasterFilter.create!(
      name: 'not used',
      match: {
        from: {
          operator: 'contains',
          value: 'nobody@example.com',
        },
      },
      perform: {
        'X-Zammad-Ticket-priority' => {
          value: '3 high',
        },
      },
      channel: 'email',
      active: true,
      created_by_id: 1,
      updated_by_id: 1,
    )

    PostmasterFilter.create!(
      name: 'used',
      match: {
        from: {
          operator: 'contains',
          value: 'me@example.com',
        },
      },
      perform: {
        'X-Zammad-Ticket-group_id' => {
          value: group1.id,
        },
        'x-Zammad-Article-Internal' => {
          value: true,
        },
      },
      channel: 'email',
      active: true,
      created_by_id: 1,
      updated_by_id: 1,
    )

    PostmasterFilter.create!(
      name: 'used x-any-recipient',
      match: {
        'x-any-recipient' => {
          operator: 'contains',
          value: 'any@example.com',
        },
      },
      perform: {
        'X-Zammad-Ticket-group_id' => {
          value: group2.id,
        },
        'x-Zammad-Article-Internal' => {
          value: true,
        },
      },
      channel: 'email',
      active: true,
      created_by_id: 1,
      updated_by_id: 1,
    )


    data = 'From: me@example.com
To: customer@example.com
Subject: some subject

Some Text'

    parser = Channel::EmailParser.new
    ticket, article, user = parser.process({ group_id: group_default.id, trusted: false }, data)
    assert_equal('Test Group1', ticket.group.name)
    assert_equal('2 normal', ticket.priority.name)
    assert_equal('some subject', ticket.title)

    assert_equal('Customer', article.sender.name)
    assert_equal('email', article.type.name)
    assert_equal(true, article.internal)

    data = 'From: Some Body <somebody@example.com>
To: Bob <bod@example.com>
Cc: any@example.com
Subject: some subject

Some Text'

    parser = Channel::EmailParser.new
    ticket, article, user = parser.process({ group_id: group_default.id, trusted: false }, data)

    assert_equal('Test Group2', ticket.group.name)
    assert_equal('2 normal', ticket.priority.name)
    assert_equal('some subject', ticket.title)

    assert_equal('Customer', article.sender.name)
    assert_equal('email', article.type.name)
    assert_equal(true, article.internal)

    PostmasterFilter.create!(
      name: 'used x-any-recipient 2',
      match: {
        'x-any-recipient' => {
          operator: 'contains not',
          value: 'any_not@example.com',
        },
      },
      perform: {
        'X-Zammad-Ticket-group_id' => {
          value: group2.id,
        },
        'X-Zammad-Ticket-priority_id' => {
          value: '1',
        },
        'x-Zammad-Article-Internal' => {
          value: 'false',
        },
      },
      channel: 'email',
      active: true,
      created_by_id: 1,
      updated_by_id: 1,
    )

    data = 'From: Some Body <somebody@example.com>
To: Bob <bod@example.com>
Cc: any@example.com
Subject: some subject2

Some Text'

    parser = Channel::EmailParser.new
    ticket, article, user = parser.process({ group_id: group_default.id, trusted: false }, data)

    assert_equal('Test Group2', ticket.group.name)
    assert_equal('1 low', ticket.priority.name)
    assert_equal('some subject2', ticket.title)

    assert_equal('Customer', article.sender.name)
    assert_equal('email', article.type.name)
    assert_equal(false, article.internal)

    PostmasterFilter.destroy_all

    # follow-up with create post master filter test
    PostmasterFilter.create!(
      name: 'used - empty selector',
      match: {
        from: {
          operator: 'contains',
          value: 'example.com',
        },
      },
      perform: {
        'X-Zammad-Ticket-group_id' => {
          value: group2.id,
        },
      },
      channel: 'email',
      active: true,
      created_by_id: 1,
      updated_by_id: 1,
    )

    data = 'From: Some Body <somebody@example.com>
To: Bob <bod@example.com>
Cc: any@example.com
Subject: follow-up with create post master filter test

Some Text'

    parser = Channel::EmailParser.new
    ticket, article, user = parser.process({ group_id: group_default.id, trusted: false }, data)

    assert_equal(group2.name, ticket.group.name)
    assert_equal('2 normal', ticket.priority.name)
    assert_equal('follow-up with create post master filter test', ticket.title)

    assert_equal('Customer', article.sender.name)
    assert_equal('email', article.type.name)
    assert_equal(false, article.internal)

    # move ticket
    ticket.group = group1
    ticket.save
    TransactionDispatcher.commit

    data = "From: me@example.com
To: customer@example.com
Subject: #{ticket.subject_build('some new subject')}

Some Text"

    article_count = ticket.articles.count

    parser = Channel::EmailParser.new
    ticket_followup, article, user = parser.process({ group_id: group_default.id, trusted: false }, data)

    # check if group is still the old one
    assert_equal(ticket.id, ticket_followup.id)
    assert_equal(group1.name, ticket_followup.group.name)
    assert_equal(group1.name, ticket_followup.group.name)
    assert_equal('2 normal', ticket_followup.priority.name)
    assert_equal('follow-up with create post master filter test', ticket_followup.title)

    assert_equal('Customer', article.sender.name)
    assert_equal('email', article.type.name)
    assert_equal(false, article.internal)
    assert_equal(article_count+1, ticket_followup.articles.count)

    PostmasterFilter.destroy_all

    PostmasterFilter.create!(
      name: 'used',
      match: {
        from: {
          operator: 'contains',
          value: 'me@example.com',
        },
      },
      perform: {
        'X-Zammad-Ticket-group_id' => {
          value: group1.id,
        },
        'x-Zammad-Article-Internal' => {
          value: true,
        },
        'x-Zammad-Ticket-customer_id' => {
          value: '',
          value_completion: '',
        },
      },
      channel: 'email',
      active: true,
      created_by_id: 1,
      updated_by_id: 1,
    )

    data = 'From: ME Bob <me@example.com>
To: customer@example.com
Subject: some subject

Some Text'

    parser = Channel::EmailParser.new
    ticket, article, user = parser.process({ group_id: group_default.id, trusted: false }, data)
    assert_equal(group1.name, ticket.group.name)
    assert_equal('2 normal', ticket.priority.name)
    assert_equal('some subject', ticket.title)
    assert_equal('me@example.com', ticket.customer.email)

    PostmasterFilter.destroy_all
    PostmasterFilter.create!(
      name: 'used',
      match: {
        from: {
          operator: 'contains',
          value: 'me@example.com',
        },
      },
      perform: {
        'X-Zammad-Ticket-group_id' => {
          value: group1.id,
        },
        'x-Zammad-Article-Internal' => {
          value: true,
        },
        'x-Zammad-Ticket-customer_id' => {
          value: 999_999,
          value_completion: 'xxx',
        },
      },
      channel: 'email',
      active: true,
      created_by_id: 1,
      updated_by_id: 1,
    )

    data = 'From: ME Bob <me@example.com>
To: customer@example.com
Subject: some subject

Some Text'

    parser = Channel::EmailParser.new
    ticket, article, user = parser.process({ group_id: group_default.id, trusted: false }, data)
    assert_equal(group1.name, ticket.group.name)
    assert_equal('2 normal', ticket.priority.name)
    assert_equal('some subject', ticket.title)
    assert_equal('me@example.com', ticket.customer.email)

    PostmasterFilter.destroy_all
    PostmasterFilter.create!(
      name: 'used',
      match: {
        from: {
          operator: 'contains',
          value: 'me@example.com',
        },
      },
      perform: {
        'X-Zammad-Ticket-group_id' => {
          value: group1.id,
        },
        'X-Zammad-Ticket-priority_id' => {
          value: 888_888,
        },
        'x-Zammad-Article-Internal' => {
          value: true,
        },
        'x-Zammad-Ticket-customer_id' => {
          value: 999_999,
          value_completion: 'xxx',
        },
      },
      channel: 'email',
      active: true,
      created_by_id: 1,
      updated_by_id: 1,
    )

    data = 'From: ME Bob <me@example.com>
To: customer@example.com
Subject: some subject

Some Text'

    parser = Channel::EmailParser.new
    ticket, article, user = parser.process({ group_id: group_default.id, trusted: false }, data)
    assert_equal(group1.name, ticket.group.name)
    assert_equal('2 normal', ticket.priority.name)
    assert_equal('some subject', ticket.title)
    assert_equal('me@example.com', ticket.customer.email)
    assert_equal('2 normal', ticket.priority.name)

    PostmasterFilter.destroy_all
    PostmasterFilter.create!(
      name: 'Autoresponder',
      match: {
        'auto-submitted' => {
          'operator' => 'contains not',
          'value' => 'auto-generated',
        },
        'from' => {
          'operator' => 'contains',
          'value' => '@example.com',
        }
      },
      perform: {
        'x-zammad-article-internal' => {
          'value' => 'true',
        },
        'x-zammad-article-type_id' => {
          'value' => Ticket::Article::Type.find_by(name: 'note').id.to_s,
        },
        'x-zammad-ignore' => {
          'value' => 'false',
        },
      },
      channel: 'email',
      active: true,
      created_by_id: 1,
      updated_by_id: 1,
    )

    data = 'From: ME Bob <me@example.com>
To: customer@example.com
Subject: some subject

Some Text'

    parser = Channel::EmailParser.new
    ticket, article, user = parser.process({ group_id: group_default.id, trusted: false }, data)
    assert_equal('Users', ticket.group.name)
    assert_equal('2 normal', ticket.priority.name)
    assert_equal('some subject', ticket.title)
    assert_equal('me@example.com', ticket.customer.email)
    assert_equal('2 normal', ticket.priority.name)

    assert_equal('Customer', article.sender.name)
    assert_equal('note', article.type.name)
    assert_equal(true, article.internal)

    PostmasterFilter.destroy_all
    PostmasterFilter.create!(
      name: 'Autoresponder',
      match: {
        'auto-submitted' => {
          'operator' => 'contains',
          'value' => 'auto-generated',
        },
        'from' => {
          'operator' => 'contains',
          'value' => '@example.com',
        }
      },
      perform: {
        'x-zammad-article-internal' => {
          'value' => 'true',
        },
        'x-zammad-article-type_id' => {
          'value' => Ticket::Article::Type.find_by(name: 'note').id.to_s,
        },
        'x-zammad-ignore' => {
          'value' => 'false',
        },
      },
      channel: 'email',
      active: true,
      created_by_id: 1,
      updated_by_id: 1,
    )

    data = 'From: ME Bob <me@example.com>
To: customer@example.com
Subject: some subject

Some Text'

    parser = Channel::EmailParser.new
    ticket, article, user = parser.process({ group_id: group_default.id, trusted: false }, data)
    assert_equal('Users', ticket.group.name)
    assert_equal('2 normal', ticket.priority.name)
    assert_equal('some subject', ticket.title)
    assert_equal('me@example.com', ticket.customer.email)
    assert_equal('2 normal', ticket.priority.name)

    assert_equal('Customer', article.sender.name)
    assert_equal('email', article.type.name)
    assert_equal(false, article.internal)

    PostmasterFilter.destroy_all
    PostmasterFilter.create!(
      name: 'Autoresponder',
      match: {
        'auto-submitted' => {
          'operator' => 'contains not',
          'value' => 'auto-generated',
        },
        'to' => {
          'operator' => 'contains',
          'value' => 'customer@example.com',
        },
        'from' => {
          'operator' => 'contains',
          'value' => '@example.com',
        }
      },
      perform: {
        'x-zammad-article-internal' => {
          'value' => 'true',
        },
        'x-zammad-article-type_id' => {
          'value' => Ticket::Article::Type.find_by(name: 'note').id.to_s,
        },
        'x-zammad-ignore' => {
          'value' => 'false',
        },
      },
      channel: 'email',
      active: true,
      created_by_id: 1,
      updated_by_id: 1,
    )

    data = 'From: ME Bob <me@example.com>
To: customer@example.com
Subject: some subject

Some Text'

    parser = Channel::EmailParser.new
    ticket, article, user = parser.process({ group_id: group_default.id, trusted: false }, data)
    assert_equal('Users', ticket.group.name)
    assert_equal('2 normal', ticket.priority.name)
    assert_equal('some subject', ticket.title)
    assert_equal('me@example.com', ticket.customer.email)
    assert_equal('2 normal', ticket.priority.name)

    assert_equal('Customer', article.sender.name)
    assert_equal('note', article.type.name)
    assert_equal(true, article.internal)

    PostmasterFilter.destroy_all
    PostmasterFilter.create!(
      name: 'Autoresponder',
      match: {
        'auto-submitted' => {
          'operator' => 'contains',
          'value' => 'auto-generated',
        },
        'to' => {
          'operator' => 'contains',
          'value' => 'customer1@example.com',
        },
        'from' => {
          'operator' => 'contains',
          'value' => '@example.com',
        }
      },
      perform: {
        'x-zammad-article-internal' => {
          'value' => 'true',
        },
        'x-zammad-article-type_id' => {
          'value' => Ticket::Article::Type.find_by(name: 'note').id.to_s,
        },
        'x-zammad-ignore' => {
          'value' => 'false',
        },
      },
      channel: 'email',
      active: true,
      created_by_id: 1,
      updated_by_id: 1,
    )

    data = 'From: ME Bob <me@example.com>
To: customer@example.com
Subject: some subject

Some Text'

    parser = Channel::EmailParser.new
    ticket, article, user = parser.process({ group_id: group_default.id, trusted: false }, data)
    assert_equal('Users', ticket.group.name)
    assert_equal('2 normal', ticket.priority.name)
    assert_equal('some subject', ticket.title)
    assert_equal('me@example.com', ticket.customer.email)
    assert_equal('2 normal', ticket.priority.name)

    assert_equal('Customer', article.sender.name)
    assert_equal('email', article.type.name)
    assert_equal(false, article.internal)
  end

  test 'tags in postmaster filter' do
    group_default = Group.lookup(name: 'Users')

    PostmasterFilter.create!(
      name: '01 set tag for email',
      match: {
        from: {
          operator: 'contains',
          value: 'nobody@example.com',
        },
      },
      perform: {
        'x-zammad-ticket-tags' => {
          operator: 'add',
          value: 'test1, test2, test3',
        },
      },
      channel: 'email',
      active: true,
      created_by_id: 1,
      updated_by_id: 1,
    )

    PostmasterFilter.create!(
      name: '02 set tag for email',
      match: {
        from: {
          operator: 'contains',
          value: 'nobody@example.com',
        },
      },
      perform: {
        'x-zammad-ticket-tags' => {
          operator: 'remove',
          value: 'test2, test3',
        },
      },
      channel: 'email',
      active: true,
      created_by_id: 1,
      updated_by_id: 1,
    )

    PostmasterFilter.create!(
      name: '03 set tag for email',
      match: {
        from: {
          operator: 'contains',
          value: 'nobody@example.com',
        },
      },
      perform: {
        'x-zammad-ticket-tags' => {
          operator: 'add',
          value: 'test3',
        },
      },
      channel: 'email',
      active: true,
      created_by_id: 1,
      updated_by_id: 1,
    )

    PostmasterFilter.create!(
      name: '04 set tag for email',
      match: {
        from: {
          operator: 'contains',
          value: 'nobody@example.com',
        },
      },
      perform: {
        'x-zammad-ticket-tags' => {
          operator: 'add',
          value: 'abc1  ,   abc2   ',
        },
      },
      channel: 'email',
      active: true,
      created_by_id: 1,
      updated_by_id: 1,
    )

    data = 'From: ME Bob <nobody@example.com>
To: customer@example.com
Subject: some subject

Some Text'

    parser = Channel::EmailParser.new
    ticket, article, user = parser.process({ group_id: group_default.id, trusted: false }, data)
    tags = Tag.tag_list(object: 'Ticket', o_id: ticket.id)
    assert_equal('Users', ticket.group.name)
    assert_equal('2 normal', ticket.priority.name)
    assert_equal('some subject', ticket.title)
    assert_equal('nobody@example.com', ticket.customer.email)
    assert_equal(4, tags.count)
    assert(tags.include?('test1'))
    assert(tags.include?('test3'))
    assert(tags.include?('abc1'))
    assert(tags.include?('abc2'))
 end
end
