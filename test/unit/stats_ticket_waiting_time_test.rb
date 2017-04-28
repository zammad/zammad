# encoding: utf-8
require 'test_helper'
require 'stats/ticket_waiting_time'

class StatsTicketWaitingTimeTest < ActiveSupport::TestCase

  test 'single ticket' do
    ticket1 = Ticket.create(
      title: 'com test 1',
      group: Group.lookup(name: 'Users'),
      customer_id: 2,
      state: Ticket::State.lookup(name: 'new'),
      priority: Ticket::Priority.lookup(name: '2 normal'),
      updated_by_id: 1,
      created_by_id: 1,
    )

    # communication 1: waiting time 2 hours (BUT too old yesterday)
    Ticket::Article.create(
      ticket_id:     ticket1.id,
      from:          'a@example.com',
      to:            'a@example.com',
      subject:       'com test 1',
      message_id:    'some@id_com_1',
      body:          'some message 123',
      internal:      false,
      sender:        Ticket::Article::Sender.find_by(name: 'Customer'),
      type:          Ticket::Article::Type.find_by(name: 'email'),
      updated_by_id: 1,
      created_by_id: 1,
      created_at:    '2017-04-12 08:00',
      updated_at:    '2017-04-12 08:00',
    )
    Ticket::Article.create(
      ticket_id:     ticket1.id,
      from:          'a@example.com',
      to:            'a@example.com',
      subject:       'com test 1',
      message_id:    'some@id_com_1',
      body:          'some message 123',
      internal:      false,
      sender:        Ticket::Article::Sender.find_by(name: 'Agent'),
      type:          Ticket::Article::Type.find_by(name: 'email'),
      updated_by_id: 1,
      created_by_id: 1,
      created_at:    '2017-04-12 10:00',
      updated_at:    '2017-04-12 10:00',
    )

    # communication 2: waiting time 2 hours
    Ticket::Article.create(
      ticket_id:     ticket1.id,
      from:          'a@example.com',
      to:            'a@example.com',
      subject:       'com test 1',
      message_id:    'some@id_com_1',
      body:          'some message 123',
      internal:      false,
      sender:        Ticket::Article::Sender.find_by(name: 'Customer'),
      type:          Ticket::Article::Type.find_by(name: 'email'),
      updated_by_id: 1,
      created_by_id: 1,
      created_at:    '2017-04-13 08:00',
      updated_at:    '2017-04-13 08:00',
    )
    Ticket::Article.create(
      ticket_id:     ticket1.id,
      from:          'a@example.com',
      to:            'a@example.com',
      subject:       'com test 1',
      message_id:    'some@id_com_1',
      body:          'some message 123',
      internal:      false,
      sender:        Ticket::Article::Sender.find_by(name: 'Agent'),
      type:          Ticket::Article::Type.find_by(name: 'email'),
      updated_by_id: 1,
      created_by_id: 1,
      created_at:    '2017-04-13 10:00',
      updated_at:    '2017-04-13 10:00',
    )

    # communication 3: waiting time 4 hours
    Ticket::Article.create(
      ticket_id:     ticket1.id,
      from:          'a@example.com',
      to:            'a@example.com',
      subject:       'com test 1',
      message_id:    'some@id_com_1',
      body:          'some message 123',
      internal:      false,
      sender:        Ticket::Article::Sender.find_by(name: 'Customer'),
      type:          Ticket::Article::Type.find_by(name: 'email'),
      updated_by_id: 1,
      created_by_id: 1,
      created_at:    '2017-04-13 11:00',
      updated_at:    '2017-04-13 11:00',
    )
    Ticket::Article.create(
      ticket_id:     ticket1.id,
      from:          'a@example.com',
      to:            'a@example.com',
      subject:       'com test 1',
      message_id:    'some@id_com_1',
      body:          'some message 123',
      internal:      false,
      sender:        Ticket::Article::Sender.find_by(name: 'System'),
      type:          Ticket::Article::Type.find_by(name: 'email'),
      updated_by_id: 1,
      created_by_id: 1,
      created_at:    '2017-04-13 15:00',
      updated_at:    '2017-04-13 15:00',
    )

    # communication 4: INVALID waiting time 1 hour (because internal)
    Ticket::Article.create(
      ticket_id:     ticket1.id,
      from:          'a@example.com',
      to:            'a@example.com',
      subject:       'com test 1',
      message_id:    'some@id_com_1',
      body:          'some message 123',
      internal:      true,
      sender:        Ticket::Article::Sender.find_by(name: 'Customer'),
      type:          Ticket::Article::Type.find_by(name: 'email'),
      updated_by_id: 1,
      created_by_id: 1,
      created_at:    '2017-04-13 15:00',
      updated_at:    '2017-04-13 15:00',
    )
    Ticket::Article.create(
      ticket_id:     ticket1.id,
      from:          'a@example.com',
      to:            'a@example.com',
      subject:       'com test 1',
      message_id:    'some@id_com_1',
      body:          'some message 123',
      internal:      true,
      sender:        Ticket::Article::Sender.find_by(name: 'System'),
      type:          Ticket::Article::Type.find_by(name: 'email'),
      updated_by_id: 1,
      created_by_id: 1,
      created_at:    '2017-04-13 15:10',
      updated_at:    '2017-04-13 15:10',
    )

    average_time = Stats::TicketWaitingTime.calculate_average([ticket1, ticket1], '2017-04-13 00:00:00')

    expected_average_time = 60 * 60 * 2 # for communication 2
    expected_average_time += 60 * 60 * 4 # for communication 3
    expected_average_time = expected_average_time / 2  # for average

    assert_equal(expected_average_time, average_time)
  end

end
