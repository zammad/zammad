# encoding: utf-8
require 'test_helper'

class TicketArticleCommunicateTest < ActiveSupport::TestCase

  test 'via config' do

    # via application server
    ApplicationHandleInfo.current = 'application_server'
    ticket1 = Ticket.create(
      title: 'com test 1',
      group: Group.lookup(name: 'Users'),
      customer_id: 2,
      state: Ticket::State.lookup(name: 'new'),
      priority: Ticket::Priority.lookup(name: '2 normal'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert(ticket1, 'ticket created')

    article_email1_1 = Ticket::Article.create(
      ticket_id: ticket1.id,
      from: 'some_customer_com-1@example.com',
      to: 'some_zammad_com-1@example.com',
      subject: 'com test 1',
      message_id: 'some@id_com_1',
      body: 'some message 123',
      internal: false,
      sender: Ticket::Article::Sender.find_by(name: 'Customer'),
      type: Ticket::Article::Type.find_by(name: 'email'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert_equal('some_customer_com-1@example.com', article_email1_1.from)
    assert_equal('some_zammad_com-1@example.com', article_email1_1.to)
    assert_equal(0, email_count('some_customer_com-1@example.com'))
    assert_equal(0, email_count('some_zammad_com-1@example.com'))
    Scheduler.worker(true)
    assert_equal('some_customer_com-1@example.com', article_email1_1.from)
    assert_equal('some_zammad_com-1@example.com', article_email1_1.to)
    assert_equal(0, email_count('some_customer_com-1@example.com'))
    assert_equal(0, email_count('some_zammad_com-1@example.com'))

    article_email1_2 = Ticket::Article.create(
      ticket_id: ticket1.id,
      from: 'some_zammad_com-1@example.com',
      to: 'some_customer_com-1@example.com',
      subject: 'com test 1',
      message_id: 'some@id_com_2',
      body: 'some message 123',
      internal: false,
      sender: Ticket::Article::Sender.find_by(name: 'Agent'),
      type: Ticket::Article::Type.find_by(name: 'email'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert_equal('Zammad <zammad@localhost>', article_email1_2.from)
    assert_equal('some_customer_com-1@example.com', article_email1_2.to)
    assert_equal(0, email_count('some_customer_com-1@example.com'))
    assert_equal(0, email_count('some_zammad_com-1@example.com'))
    Scheduler.worker(true)
    assert_equal('Zammad <zammad@localhost>', article_email1_2.from)
    assert_equal('some_customer_com-1@example.com', article_email1_2.to)
    assert_equal(1, email_count('some_customer_com-1@example.com'))
    assert_equal(0, email_count('some_zammad_com-1@example.com'))

    # via scheduler (e. g. postmaster)
    ApplicationHandleInfo.current = 'scheduler.postmaster'
    ticket2 = Ticket.create(
      title: 'com test 2',
      group: Group.lookup(name: 'Users'),
      customer_id: 2,
      state: Ticket::State.lookup(name: 'new'),
      priority: Ticket::Priority.lookup(name: '2 normal'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert(ticket2, 'ticket created')

    article_email2_1 = Ticket::Article.create(
      ticket_id: ticket2.id,
      from: 'some_customer_com-2@example.com',
      to: 'some_zammad_com-2@example.com',
      subject: 'com test 2',
      message_id: 'some@id_com_1',
      body: 'some message 123',
      internal: false,
      sender: Ticket::Article::Sender.find_by(name: 'Customer'),
      type: Ticket::Article::Type.find_by(name: 'email'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert_equal('some_customer_com-2@example.com', article_email2_1.from)
    assert_equal('some_zammad_com-2@example.com', article_email2_1.to)
    assert_equal(0, email_count('some_customer_com-2@example.com'))
    assert_equal(0, email_count('some_zammad_com-2@example.com'))
    Scheduler.worker(true)
    assert_equal('some_customer_com-2@example.com', article_email2_1.from)
    assert_equal('some_zammad_com-2@example.com', article_email2_1.to)
    assert_equal(0, email_count('some_customer_com-2@example.com'))
    assert_equal(0, email_count('some_zammad_com-2@example.com'))

    ApplicationHandleInfo.current = 'scheduler.postmaster'
    article_email2_2 = Ticket::Article.create(
      ticket_id: ticket2.id,
      from: 'some_zammad_com-2@example.com',
      to: 'some_customer_com-2@example.com',
      subject: 'com test 2',
      message_id: 'some@id_com_2',
      body: 'some message 123',
      internal: false,
      sender: Ticket::Article::Sender.find_by(name: 'Agent'),
      type: Ticket::Article::Type.find_by(name: 'email'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert_equal(0, email_count('some_customer_com-2@example.com'))
    assert_equal(0, email_count('some_zammad_com-2@example.com'))
    assert_equal('some_zammad_com-2@example.com', article_email2_2.from)
    assert_equal('some_customer_com-2@example.com', article_email2_2.to)
    Scheduler.worker(true)
    assert_equal(0, email_count('some_customer_com-2@example.com'))
    assert_equal(0, email_count('some_zammad_com-2@example.com'))
    assert_equal('some_zammad_com-2@example.com', article_email2_2.from)
    assert_equal('some_customer_com-2@example.com', article_email2_2.to)
  end

  test 'postmaster process - do not change from - verify article sender' do
    email_raw_string = "From: my_zammad@example.com
To: customer@example.com
Subject: some subject
X-Zammad-Article-Sender: Agent
X-Loop: yes

Some Text"

    ticket_p, article_p, user_p, mail = Channel::EmailParser.new.process({ trusted: true }, email_raw_string)
    ticket = Ticket.find(ticket_p.id)
    article_email = Ticket::Article.find(article_p.id)

    assert_equal(0, email_count('my_zammad@example.com'))
    assert_equal(0, email_count('customer@example.com'))
    assert_equal('my_zammad@example.com', article_email.from)
    assert_equal('customer@example.com', article_email.to)
    assert_equal('Agent', article_email.sender.name)
    assert_equal('email', article_email.type.name)
    assert_equal(1, article_email.ticket.articles.count)

    Scheduler.worker(true)
    article_email = Ticket::Article.find(article_p.id)
    assert_equal(0, email_count('my_zammad@example.com'))
    assert_equal(0, email_count('customer@example.com'))
    assert_equal('my_zammad@example.com', article_email.from)
    assert_equal('customer@example.com', article_email.to)
    assert_equal('Agent', article_email.sender.name)
    assert_equal('email', article_email.type.name)
    assert_equal(1, article_email.ticket.articles.count)
  end

end
