
require 'test_helper'

class TicketStateChangeTest < ActiveSupport::TestCase

  test 'check if after reply ticket is open' do

    ticket1 = Ticket.create!(
      title: 'com test 1',
      group: Group.lookup(name: 'Users'),
      customer_id: 2,
      state: Ticket::State.lookup(name: 'new'),
      priority: Ticket::Priority.lookup(name: '2 normal'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert(ticket1, 'ticket created')

    article1 = Ticket::Article.create!(
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

    Observer::Transaction.commit
    Scheduler.worker(true)

    ticket1.reload
    assert_equal('new', ticket1.state.name)

    ticket1.with_lock do
      ticket1.update!(state_id: Ticket::State.find_by(name: 'new').id)
      article2 = Ticket::Article.create!(
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
    end

    Observer::Transaction.commit
    Scheduler.worker(true)

    ticket1.reload
    assert_equal('open', ticket1.state.name)

  end

  test 'check if after reply ticket is closed' do

    ticket1 = Ticket.create!(
      title: 'com test 1',
      group: Group.lookup(name: 'Users'),
      customer_id: 2,
      state: Ticket::State.lookup(name: 'new'),
      priority: Ticket::Priority.lookup(name: '2 normal'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert(ticket1, 'ticket created')

    article1 = Ticket::Article.create!(
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

    Observer::Transaction.commit
    Scheduler.worker(true)

    ticket1.reload
    assert_equal('new', ticket1.state.name)

    ticket1.with_lock do
      ticket1.update!(state_id: Ticket::State.find_by(name: 'closed').id)

      article2 = Ticket::Article.create!(
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
    end

    Observer::Transaction.commit
    Scheduler.worker(true)

    ticket1.reload
    assert_equal('closed', ticket1.state.name)

  end

end
