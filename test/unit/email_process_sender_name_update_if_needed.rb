# encoding: utf-8
require 'test_helper'

class EmailProcessSenderNameUpdateIfNeeded < ActiveSupport::TestCase

  test 'basic' do
    email_raw_string = "From: customer@example.com
To: myzammad@example.com
Subject: test sender name update 1

Some Text"

    ticket_p, article_p, user_p, mail = Channel::EmailParser.new.process({}, email_raw_string)
    ticket = Ticket.find(ticket_p.id)
    article = Ticket::Article.find(article_p.id)
    assert_equal('test sender name update 1', ticket.title)
    assert_equal('new', ticket.state.name)
    assert_equal('Customer', ticket.create_article_sender.name)
    assert_equal('Customer', article.sender.name)
    assert_equal('customer@example.com', ticket.customer.email)
    assert_equal('', ticket.customer.firstname)
    assert_equal('', ticket.customer.lastname)

    email_raw_string = "From: Max Smith <customer@example.com>
To: myzammad@example.com
Subject: test sender name update 2

Some Text"

    ticket_p, article_p, user_p, mail = Channel::EmailParser.new.process({}, email_raw_string)
    ticket = Ticket.find(ticket_p.id)
    article = Ticket::Article.find(article_p.id)
    assert_equal('test sender name update 2', ticket.title)
    assert_equal('new', ticket.state.name)
    assert_equal('Customer', ticket.create_article_sender.name)
    assert_equal('Customer', article.sender.name)
    assert_equal('customer@example.com', ticket.customer.email)
    assert_equal('Max', ticket.customer.firstname)
    assert_equal('Smith', ticket.customer.lastname)

  end
end
