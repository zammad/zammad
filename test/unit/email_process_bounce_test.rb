# encoding: utf-8
require 'test_helper'

class EmailProcessBounceTest < ActiveSupport::TestCase

  test 'process with bounce check' do

    ticket = Ticket.create(
      title: 'bounce check',
      group: Group.lookup( name: 'Users'),
      customer_id: 2,
      state: Ticket::State.lookup( name: 'new' ),
      priority: Ticket::Priority.lookup( name: '2 normal' ),
      updated_by_id: 1,
      created_by_id: 1,
    )
    article = Ticket::Article.create(
      ticket_id: ticket.id,
      from: 'some_sender@example.com',
      to: 'some_recipient@example.com',
      subject: 'bounce check',
      message_id: '<20150830145601.30.608881@edenhofer.zammad.com>',
      body: 'some message bounce check',
      internal: false,
      sender: Ticket::Article::Sender.where(name: 'Customer').first,
      type: Ticket::Article::Type.where(name: 'email').first,
      updated_by_id: 1,
      created_by_id: 1,
    )
    sleep 1
    email_raw_string = IO.binread('test/fixtures/mail33-undelivered-mail-returned-to-sender.box')
    ticket_p, article_p, user_p = Channel::EmailParser.new.process({}, email_raw_string)
    assert_equal(ticket.id, ticket_p.id)
    assert_equal('new', ticket_p.state.name)
  end

end
