# encoding: utf-8
require 'test_helper'

class EmailProcessBounceDeliveryPermanentFailedTest < ActiveSupport::TestCase

  test 'process with bounce trigger email loop check - article based blocker' do
    roles = Role.where(name: %w(Customer))
    customer1 = User.create_or_update(
      login: 'ticket-bounce-trigger1@example.com',
      firstname: 'Notification',
      lastname: 'Customer1',
      email: 'ticket-bounce-trigger1@example.com',
      active: true,
      roles: roles,
      preferences: {},
      updated_by_id: 1,
      created_by_id: 1,
    )

    Trigger.create_or_update(
      name: 'auto reply new ticket',
      condition: {
        'ticket.action' => {
          'operator' => 'is',
          'value' => 'create',
        },
      },
      perform: {
        'notification.email' => {
          'body' => 'some text<br>#{ticket.customer.lastname}<br>#{ticket.title}<br>#{article.body}',
          'recipient' => 'ticket_customer',
          'subject' => 'Thanks for your inquiry (#{ticket.title})!',
        },
      },
      disable_notification: true,
      active: true,
      created_by_id: 1,
      updated_by_id: 1,
    )
    Trigger.create_or_update(
      name: 'auto reply followup',
      condition: {
        'ticket.action' => {
          'operator' => 'is',
          'value' => 'update',
        },
      },
      perform: {
        'notification.email' => {
          'body' => 'some text<br>#{ticket.customer.lastname}<br>#{ticket.title}<br>#{article.body}',
          'recipient' => 'ticket_customer',
          'subject' => 'Thanks for your follow up (#{ticket.title})!',
        },
      },
      disable_notification: true,
      active: true,
      created_by_id: 1,
      updated_by_id: 1,
    )

    ticket = Ticket.create(
      title: 'bounce check',
      group: Group.lookup(name: 'Users'),
      customer: customer1,
      state: Ticket::State.lookup(name: 'new'),
      priority: Ticket::Priority.lookup(name: '2 normal'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    article = Ticket::Article.create(
      ticket_id: ticket.id,
      from: 'some_sender@example.com',
      to: 'some_recipient@example.com',
      subject: 'bounce check',
      message_id: '<20150830145601.30.6088xx@edenhofer.zammad.com>',
      body: 'some message bounce check',
      internal: false,
      sender: Ticket::Article::Sender.where(name: 'Agent').first,
      type: Ticket::Article::Type.where(name: 'email').first,
      updated_by_id: 1,
      created_by_id: 1,
    )
    Observer::Transaction.commit
    assert_equal('new', ticket.state.name)
    assert_equal(2, ticket.articles.count)

    article = Ticket::Article.create(
      ticket_id: ticket.id,
      from: 'some_sender@example.com',
      to: customer1.email,
      subject: 'bounce check 2',
      message_id: '<20150830145601.30.608881@edenhofer.zammad.com>',
      body: 'some message bounce check 2',
      internal: false,
      sender: Ticket::Article::Sender.where(name: 'Agent').first,
      type: Ticket::Article::Type.where(name: 'email').first,
      updated_by_id: 1,
      created_by_id: 1,
    )
    Observer::Transaction.commit
    assert_equal(4, ticket.articles.count)

    travel 1.second
    email_raw_string = IO.binread('test/fixtures/mail33-undelivered-mail-returned-to-sender.box')
    ticket_p, article_p, user_p = Channel::EmailParser.new.process({}, email_raw_string)
    assert_equal(ticket.id, ticket_p.id)
    assert_equal('open', ticket_p.state.name)
    assert_equal(5, ticket_p.articles.count)
    travel_back
    ticket.destroy
  end

  test 'process with bounce trigger email loop check - bounce based blocker' do
    roles = Role.where(name: %w(Customer))
    customer2 = User.create_or_update(
      login: 'ticket-bounce-trigger2@example.com',
      firstname: 'Notification',
      lastname: 'Customer2',
      email: 'ticket-bounce-trigger2@example.com',
      active: true,
      roles: roles,
      preferences: {},
      updated_by_id: 1,
      created_by_id: 1,
    )

    Trigger.create_or_update(
      name: 'auto reply new ticket',
      condition: {
        'ticket.action' => {
          'operator' => 'is',
          'value' => 'create',
        },
      },
      perform: {
        'notification.email' => {
          'body' => 'some text<br>#{ticket.customer.lastname}<br>#{ticket.title}<br>#{article.body}',
          'recipient' => 'ticket_customer',
          'subject' => 'Thanks for your inquiry (#{ticket.title})!',
        },
      },
      disable_notification: true,
      active: true,
      created_by_id: 1,
      updated_by_id: 1,
    )
    Trigger.create_or_update(
      name: 'auto reply followup',
      condition: {
        'ticket.action' => {
          'operator' => 'is',
          'value' => 'update',
        },
      },
      perform: {
        'notification.email' => {
          'body' => 'some text<br>#{ticket.customer.lastname}<br>#{ticket.title}<br>#{article.body}',
          'recipient' => 'ticket_customer',
          'subject' => 'Thanks for your follow up (#{ticket.title})!',
        },
      },
      disable_notification: true,
      active: true,
      created_by_id: 1,
      updated_by_id: 1,
    )

    ticket = Ticket.create(
      title: 'bounce check',
      group: Group.lookup(name: 'Users'),
      customer: customer2,
      state: Ticket::State.lookup(name: 'new'),
      priority: Ticket::Priority.lookup(name: '2 normal'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    article = Ticket::Article.create(
      ticket_id: ticket.id,
      from: 'some_sender@example.com',
      to: 'some_recipient@example.com',
      subject: 'bounce check',
      message_id: '<20150830145601.30.6088xx@edenhofer.zammad.com>',
      body: 'some message bounce check',
      internal: false,
      sender: Ticket::Article::Sender.where(name: 'Agent').first,
      type: Ticket::Article::Type.where(name: 'email').first,
      updated_by_id: 1,
      created_by_id: 1,
    )
    Observer::Transaction.commit
    assert_equal('new', ticket.state.name)
    assert_equal(2, ticket.articles.count)

    article = Ticket::Article.create(
      ticket_id: ticket.id,
      from: 'some_sender@example.com',
      to: 'some_recipient@example.com',
      subject: 'bounce check 2',
      message_id: '<20170526150141.232.13312@example.zammad.loc>',
      body: 'some message bounce check 2',
      internal: false,
      sender: Ticket::Article::Sender.where(name: 'Agent').first,
      type: Ticket::Article::Type.where(name: 'email').first,
      updated_by_id: 1,
      created_by_id: 1,
    )
    Observer::Transaction.commit
    assert_equal(4, ticket.articles.count)

    travel 1.second
    email_raw_string = IO.binread('test/fixtures/mail55.box')
    ticket_p, article_p, user_p = Channel::EmailParser.new.process({}, email_raw_string)
    assert_equal(ticket.id, ticket_p.id)
    assert_equal('open', ticket_p.state.name)
    assert_equal(5, ticket_p.articles.count)
    travel_back
    ticket.destroy
  end

end
