# encoding: utf-8
require 'test_helper'

class TicketArticleTimeAccoutingTest < ActiveSupport::TestCase

  test 'destroy dependent time accounting for ticket and article' do
    ticket_test = Ticket.create(
      title: 'com test 1',
      group: Group.lookup(name: 'Users'),
      customer_id: 2,
      state: Ticket::State.lookup(name: 'new'),
      priority: Ticket::Priority.lookup(name: '2 normal'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert(ticket_test, 'ticket created')

    article_test1 = Ticket::Article.create(
      ticket_id: ticket_test.id,
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

    Ticket::TimeAccounting.create!(
      ticket_id: ticket_test.id,
      ticket_article_id: article_test1.id,
      time_unit: 10,
      created_by_id: 1,
    )

    article_test2 = Ticket::Article.create(
      ticket_id: ticket_test.id,
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

    Ticket::TimeAccounting.create!(
      ticket_id: ticket_test.id,
      ticket_article_id: article_test2.id,
      time_unit: 10,
      created_by_id: 1,
    )

    article_test3 = Ticket::Article.create(
      ticket_id: ticket_test.id,
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

    Ticket::TimeAccounting.create!(
      ticket_id: ticket_test.id,
      ticket_article_id: article_test3.id,
      time_unit: 10,
      created_by_id: 1,
    )

    Ticket::TimeAccounting.create!(
      ticket_id: ticket_test.id,
      time_unit: 10,
      created_by_id: 1,
    )

    time_accouting_list = Ticket::TimeAccounting.where(
      ticket_id: ticket_test.id,
    )

    found = time_accouting_list.select { |t| t.ticket_article_id.in?([article_test1.id, article_test2.id, article_test3.id]) }
    assert_equal(3, found.count)

    article_test1.destroy

    time_accouting_list.reload
    found = time_accouting_list.select { |t| t.ticket_article_id.in?([article_test1.id, article_test2.id, article_test3.id]) }
    assert_equal(2, found.count)

    article_test2.destroy

    time_accouting_list.reload
    found = time_accouting_list.select { |t| t.ticket_article_id.in?([article_test1.id, article_test2.id, article_test3.id]) }
    assert_equal(1, found.count)

    article_test3.destroy

    time_accouting_list.reload
    found = time_accouting_list.select { |t| t.ticket_article_id.in?([article_test1.id, article_test2.id, article_test3.id]) }
    assert_equal(0, found.count)

    # one accouting left for the ticket only
    assert_equal(1, time_accouting_list.count)
    ticket_test.destroy
    time_accouting_list.reload
    assert_equal(0, time_accouting_list.count)
  end
end
