# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'test_helper'

class EmailProcessSenderIsSystemAddressOrAgent < ActiveSupport::TestCase

  setup do
    EmailAddress.create_or_update(
      channel_id:    1,
      realname:      'My System',
      email:         'Myzammad@system.TEST',
      active:        true,
      updated_by_id: 1,
      created_by_id: 1,
    )
  end

  test 'process email with sender as system address check' do
    subject = "some new subject #{rand(9_999_999)}"
    email_raw_string = "From: me+is+customer@example.com
To: customer@example.com
Subject: #{subject}

Some Text"

    ticket_p, article_p, _user_p, _mail = Channel::EmailParser.new.process({}, email_raw_string)
    ticket = Ticket.find(ticket_p.id)
    article = Ticket::Article.find(article_p.id)
    assert_equal(subject, ticket.title)
    assert_equal('new', ticket.state.name)
    assert_equal('Customer', ticket.create_article_sender.name)
    assert_equal('Customer', article.sender.name)
    assert_equal('me+is+customer@example.com', ticket.customer.email)

    # check article sender + customer of ticket
    subject = "some new subject #{rand(9_999_999)}"
    email_raw_string = "From: myzammad@system.test
To: me+is+customer@example.com, customer@example.com
Subject: #{subject}
Message-ID: <123456789-1@linuxhotel.de>


Some Text"

    ticket_p, article_p, _user_p, _mail = Channel::EmailParser.new.process({}, email_raw_string)
    ticket = Ticket.find(ticket_p.id)
    article = Ticket::Article.find(article_p.id)

    assert_equal(subject, ticket.title)
    assert_equal('new', ticket.state.name)
    assert_equal('Agent', ticket.create_article_sender.name)
    assert_equal('Agent', article.sender.name)
    assert_equal('me+is+customer@example.com', ticket.customer.email)

    # check if follow-up based on inital system sender address
    setting_orig = Setting.get('postmaster_follow_up_search_in')
    Setting.set('postmaster_follow_up_search_in', [])

    # follow-up possible because same subject
    email_raw_string = "From: me+is+customer@example.com
To: myzammad@system.test
Subject: #{subject}
Message-ID: <123456789-2@linuxhotel.de>
References: <123456789-1@linuxhotel.de>

Some Text"

    ticket_p2, _article_p, _user_p, _mail = Channel::EmailParser.new.process({}, email_raw_string)
    ticket2 = Ticket.find(ticket_p2.id)
    assert_equal(subject, ticket2.title)
    assert_equal(ticket.id, ticket2.id)

    # follow-up not possible because subject has changed
    subject = "new subject without ticket ref #{rand(9_999_999)}"
    email_raw_string = "From: me+is+customer@example.com
To: myzammad@system.test
Subject: #{subject}
Message-ID: <123456789-3@linuxhotel.de>
References: <123456789-1@linuxhotel.de>

Some Text"

    ticket_p2, _article_p, _user_p, _mail = Channel::EmailParser.new.process({}, email_raw_string)
    ticket2 = Ticket.find(ticket_p2.id)
    assert_not_equal(ticket.id, ticket2.id)
    assert_equal(subject, ticket2.title)
    assert_equal('new', ticket2.state.name)

    Setting.set('postmaster_follow_up_search_in', setting_orig)

  end

  test 'process email with sender as agent address check' do

    # create customer
    roles = Role.where(name: 'Customer')
    customer1 = User.create_or_update(
      login:         'ticket-system-sender-customer1@example.com',
      firstname:     'system-sender',
      lastname:      'Customer1',
      email:         'ticket-system-sender-customer1@example.com',
      password:      'customerpw',
      active:        true,
      roles:         roles,
      updated_by_id: 1,
      created_by_id: 1,
    )

    # create agent
    groups = Group.all
    roles  = Role.where(name: 'Agent')
    agent1 = User.create_or_update(
      login:         'ticket-system-sender-agent1@example.com',
      firstname:     'system-sender',
      lastname:      'Agent1',
      email:         'ticket-system-sender-agent1@example.com',
      password:      'agentpw',
      active:        true,
      roles:         roles,
      groups:        groups,
      updated_by_id: 1,
      created_by_id: 1,
    )

    # process customer email
    email_raw_string = "From: ticket-system-sender-customer1@example.com
To: myzammad@system.test
Subject: some subject #1

Some Text"

    ticket_p, article_p, _user_p, _mail = Channel::EmailParser.new.process({}, email_raw_string)
    ticket = Ticket.find(ticket_p.id)
    article = Ticket::Article.find(article_p.id)
    assert_equal('some subject #1', ticket.title)
    assert_equal('new', ticket.state.name)
    assert_equal('Customer', ticket.create_article_sender.name)
    assert_equal('Customer', article.sender.name)
    assert_equal('ticket-system-sender-customer1@example.com', ticket.customer.email)
    assert_equal(customer1.id, ticket.created_by_id)
    assert_equal(customer1.id, article.created_by_id)

    # process agent email
    email_raw_string = "From: ticket-system-sender-agent1@example.com
To: ticket-system-sender-customer1@example.com, myzammad@system.test
Subject: some subject #2

Some Text"

    ticket_p, article_p, _user_p, _mail = Channel::EmailParser.new.process({}, email_raw_string)
    ticket = Ticket.find(ticket_p.id)
    article = Ticket::Article.find(article_p.id)
    assert_equal('some subject #2', ticket.title)
    assert_equal('new', ticket.state.name)
    assert_equal('Agent', ticket.create_article_sender.name)
    assert_equal('Agent', article.sender.name)
    assert_equal('ticket-system-sender-customer1@example.com', ticket.customer.email)
    assert_equal(agent1.id, ticket.created_by_id)
    assert_equal(agent1.id, article.created_by_id)

    email_raw_string = "From: ticket-system-sender-agent1@example.com
To: myzammad@system.test, ticket-system-sender-customer1@example.com
Subject: some subject #3

Some Text"

    ticket_p, article_p, _user_p, _mail = Channel::EmailParser.new.process({}, email_raw_string)
    ticket = Ticket.find(ticket_p.id)
    article = Ticket::Article.find(article_p.id)
    assert_equal('some subject #3', ticket.title)
    assert_equal('new', ticket.state.name)
    assert_equal('Agent', ticket.create_article_sender.name)
    assert_equal('Agent', article.sender.name)
    assert_equal('ticket-system-sender-customer1@example.com', ticket.customer.email)
    assert_equal(agent1.id, ticket.created_by_id)
    assert_equal(agent1.id, article.created_by_id)

    email_raw_string = "From: ticket-system-sender-AGENT1@example.com
To: MYZAMMAD@system.test, ticket-system-sender-CUSTOMER1@example.com
Subject: some subject #4

Some Text"

    ticket_p, article_p, _user_p, _mail = Channel::EmailParser.new.process({}, email_raw_string)
    ticket = Ticket.find(ticket_p.id)
    article = Ticket::Article.find(article_p.id)
    assert_equal('some subject #4', ticket.title)
    assert_equal('new', ticket.state.name)
    assert_equal('Agent', ticket.create_article_sender.name)
    assert_equal('Agent', article.sender.name)
    assert_equal('ticket-system-sender-customer1@example.com', ticket.customer.email)
    assert_equal(agent1.id, ticket.created_by_id)
    assert_equal(agent1.id, article.created_by_id)

    email_raw_string = "From: ticket-system-sender-agent1@example.com
To: myzammad@system.test
Subject: some subject #5

Some Text"

    ticket_p, article_p, _user_p, _mail = Channel::EmailParser.new.process({}, email_raw_string)
    ticket = Ticket.find(ticket_p.id)
    article = Ticket::Article.find(article_p.id)
    assert_equal('some subject #5', ticket.title)
    assert_equal('new', ticket.state.name)
    assert_equal('Agent', ticket.create_article_sender.name)
    assert_equal('Agent', article.sender.name)
    assert_equal('ticket-system-sender-agent1@example.com', ticket.customer.email)
    assert_equal(agent1.id, ticket.created_by_id)
    assert_equal(agent1.id, article.created_by_id)

    email_raw_string = "From: ticket-system-sender-agent1@example.com
To: myZammad@system.Test
Subject: some subject #6

Some Text"

    ticket_p, article_p, _user_p, _mail = Channel::EmailParser.new.process({}, email_raw_string)
    ticket = Ticket.find(ticket_p.id)
    article = Ticket::Article.find(article_p.id)
    assert_equal('some subject #6', ticket.title)
    assert_equal('new', ticket.state.name)
    assert_equal('Agent', ticket.create_article_sender.name)
    assert_equal('Agent', article.sender.name)
    assert_equal('ticket-system-sender-agent1@example.com', ticket.customer.email)
    assert_equal(agent1.id, ticket.created_by_id)
    assert_equal(agent1.id, article.created_by_id)

  end
end
