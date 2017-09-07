# encoding: utf-8
require 'test_helper'

class TicketNullByteTest < ActiveSupport::TestCase
  test 'null byte test' do
    ticket1 = Ticket.create!(
      title: "some title \u0000 123",
      group: Group.lookup(name: 'Users'),
      customer_id: 2,
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert(ticket1, 'ticket created')

    article1 = Ticket::Article.create!(
      ticket_id: ticket1.id,
      from: 'some_customer_com-1@example.com',
      to: 'some_zammad_com-1@example.com',
      subject: "com test 1\u0000",
      message_id: 'some@id_com_1',
      body: "some\u0000message 123",
      internal: false,
      sender: Ticket::Article::Sender.find_by(name: 'Customer'),
      type: Ticket::Article::Type.find_by(name: 'email'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert(article1, 'ticket created')

    ticket1.destroy!
    article1.destroy!

  end
end
