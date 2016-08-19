# encoding: utf-8
require 'test_helper'

class EmailProcessSenderIsSystemAddress < ActiveSupport::TestCase

  test 'process with ticket creates and system address check' do

    EmailAddress.create_or_update(
      channel_id: 1,
      realname: 'My System',
      email: 'my@system.test',
      active: true,
      updated_by_id: 1,
      created_by_id: 1,
    )
    subject = "some new subject #{rand(9_999_999)}"
    email_raw_string = "From: me@example.com
To: customer@example.com
Subject: #{subject}

Some Text"

    ticket_p, article_p, user_p, mail = Channel::EmailParser.new.process({}, email_raw_string)
    ticket = Ticket.find(ticket_p.id)
    article = Ticket::Article.find(article_p.id)
    assert_equal(subject, ticket.title)
    assert_equal('new', ticket.state.name)
    assert_equal('Customer', ticket.create_article_sender.name)
    assert_equal('Customer', article.sender.name)
    assert_equal('me@example.com', ticket.customer.email)

    # check article sender + customer of ticket
    subject = "some new subject #{rand(9_999_999)}"
    email_raw_string = "From: my@system.test
To: me@example.com, customer@example.com
Subject: #{subject}
Message-ID: <123456789-1@linuxhotel.de>


Some Text"

    ticket_p, article_p, user_p, mail = Channel::EmailParser.new.process({}, email_raw_string)
    ticket = Ticket.find(ticket_p.id)
    article = Ticket::Article.find(article_p.id)
    p "ticket: #{ticket.inspect}"
    assert_equal(subject, ticket.title)
    assert_equal('open', ticket.state.name)
    assert_equal('Agent', ticket.create_article_sender.name)
    assert_equal('Agent', article.sender.name)
    assert_equal('me@example.com', ticket.customer.email)

    # check if follow up based on inital system sender address
    setting_orig = Setting.get('postmaster_follow_up_search_in')
    Setting.set('postmaster_follow_up_search_in', [])

    # follow up possible because same subject
    email_raw_string = "From: me@example.com
To: my@system.test
Subject: #{subject}
Message-ID: <123456789-2@linuxhotel.de>
References: <123456789-1@linuxhotel.de>

Some Text"

    ticket_p2, article_p, user_p, mail = Channel::EmailParser.new.process({}, email_raw_string)
    ticket2 = Ticket.find(ticket_p2.id)
    article = Ticket::Article.find(article_p.id)
    assert_equal(subject, ticket2.title)
    assert_equal(ticket.id, ticket2.id)

    # follow up not possible because subject has changed
    subject = "new subject without ticket ref #{rand(9_999_999)}"
    email_raw_string = "From: me@example.com
To: my@system.test
Subject: #{subject}
Message-ID: <123456789-3@linuxhotel.de>
References: <123456789-1@linuxhotel.de>

Some Text"

    ticket_p2, article_p, user_p, mail = Channel::EmailParser.new.process({}, email_raw_string)
    ticket2 = Ticket.find(ticket_p2.id)
    article = Ticket::Article.find(article_p.id)
    assert_not_equal(ticket.id, ticket2.id)
    assert_equal(subject, ticket2.title)
    assert_equal('new', ticket2.state.name)

    Setting.set('postmaster_follow_up_search_in', setting_orig)

  end

end
