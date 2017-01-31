# encoding: utf-8
require 'test_helper'

class EmailProcessFollowUpPossibleTest < ActiveSupport::TestCase

  test 'process with follow up possible check' do

    users_group = Group.lookup(name: 'Users')

    ticket = Ticket.create(
      title: 'follow up check',
      group: users_group,
      customer_id: 2,
      state: Ticket::State.lookup(name: 'new'),
      priority: Ticket::Priority.lookup(name: '2 normal'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    article = Ticket::Article.create(
      ticket_id: ticket.id,
      from: 'some_sender@example.com',
      to: 'some_recipient@example.com',
      subject: 'follow up check',
      message_id: '<20150830145601.30.608882@edenhofer.zammad.com>',
      body: 'some message article',
      internal: false,
      sender: Ticket::Article::Sender.lookup(name: 'Agent'),
      type: Ticket::Article::Type.lookup(name: 'email'),
      updated_by_id: 1,
      created_by_id: 1,
    )

    follow_up_raw = "From: me@example.com
To: customer@example.com
Subject: #{ticket.subject_build('some new subject')}

Some Text"

    users_group.update_attribute('follow_up_possible', 'new_ticket')

    travel 1.second
    ticket_p, article_p, user_p = Channel::EmailParser.new.process({}, follow_up_raw)
    assert_equal(ticket.id, ticket_p.id)
    assert_equal('follow up check', ticket_p.title)
    assert_match('some new subject', article_p.subject)

    # close ticket
    ticket.state = Ticket::State.find_by(name: 'closed')
    ticket.save!

    follow_up_raw = "From: me@example.com
To: customer@example.com
Subject: #{ticket.subject_build('some new subject2')}

Some Text"

    travel 1.second
    ticket_p, article_p, user_p = Channel::EmailParser.new.process({}, follow_up_raw)
    assert_not_equal(ticket.id, ticket_p.id)
    assert_equal('some new subject2', ticket_p.title)
    assert_equal('some new subject2', article_p.subject)

    users_group.update_attribute('follow_up_possible', 'yes')

    travel 1.second
    ticket_p, article_p, user_p = Channel::EmailParser.new.process({}, follow_up_raw)
    assert_equal(ticket.id, ticket_p.id)
    assert_equal('follow up check', ticket_p.title)
    assert_match('some new subject', article_p.subject)
    travel_back
  end
end
