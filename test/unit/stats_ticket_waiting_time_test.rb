
require 'test_helper'
require 'stats/ticket_waiting_time'

class StatsTicketWaitingTimeTest < ActiveSupport::TestCase

  test 'single ticket' do

    group1 = Group.create!(
      name: 'Group 1',
      active: true,
      email_address: EmailAddress.first,
      created_by_id: 1,
      updated_by_id: 1,
    )
    roles = Role.where(name: 'Agent')
    user1 = User.create!(
      login: 'assets_stats1@example.org',
      firstname: 'assets_stats1',
      lastname: 'assets_stats1',
      email: 'assets_stats1@example.org',
      password: 'some_pass',
      active: true,
      groups: [group1],
      roles: roles,
      created_by_id: 1,
      updated_by_id: 1,
    )
    user2 = User.create!(
      login: 'assets_stats2@example.org',
      firstname: 'assets_stats2',
      lastname: 'assets_stats2',
      email: 'assets_sla2@example.org',
      password: 'some_pass',
      active: true,
      groups: [group1],
      roles: roles,
      created_by_id: 1,
      updated_by_id: 1,
    )

    result = Stats::TicketWaitingTime.generate(user1)
    assert_equal(0, result[:handling_time])
    assert_equal('supergood', result[:state])
    assert_equal(0, result[:average_per_agent])
    assert_equal(0, result[:percent])

    ticket1 = Ticket.create!(
      title: 'com test 1',
      group: group1,
      customer_id: 2,
      state: Ticket::State.lookup(name: 'new'),
      priority: Ticket::Priority.lookup(name: '2 normal'),
      updated_by_id: 1,
      created_by_id: 1,
    )

    # communication 1: waiting time 2 hours (BUT too old yesterday)
    Ticket::Article.create!(
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
    Ticket::Article.create!(
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
    Ticket::Article.create!(
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
    Ticket::Article.create!(
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
    Ticket::Article.create!(
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
    Ticket::Article.create!(
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
    Ticket::Article.create!(
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
    Ticket::Article.create!(
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

    ticket2 = Ticket.create!(
      title: 'com test 2',
      group: group1,
      customer_id: 2,
      state: Ticket::State.lookup(name: 'new'),
      priority: Ticket::Priority.lookup(name: '2 normal'),
      updated_by_id: 1,
      created_by_id: 1,
    )

    average_time = Stats::TicketWaitingTime.calculate_average([ticket1.id, ticket2.id], '2017-04-13 00:00:00')

    expected_average_time = 60 * 60 * 2 # for communication 2
    expected_average_time += 60 * 60 * 4 # for communication 3
    expected_average_time = expected_average_time / 2  # for average

    travel_to Time.zone.local(2017, 0o4, 13, 23, 0o0, 44)

    assert_equal(expected_average_time, average_time)

    result = Stats::TicketWaitingTime.generate(user1)
    assert_equal(0, result[:handling_time])
    assert_equal('supergood', result[:state])
    assert_equal(180, result[:average_per_agent])
    assert_equal(0.0, result[:percent])

    ticket3 = Ticket.create!(
      title: 'com test 3',
      group: group1,
      customer_id: 2,
      owner: user1,
      state: Ticket::State.lookup(name: 'new'),
      priority: Ticket::Priority.lookup(name: '2 normal'),
      updated_by_id: 1,
      created_by_id: 1,
    )

    # communication 1: waiting time 2 hours (BUT too old yesterday)
    Ticket::Article.create!(
      ticket_id:     ticket3.id,
      from:          'a@example.com',
      to:            'a@example.com',
      subject:       'com test 3',
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
    Ticket::Article.create!(
      ticket_id:     ticket3.id,
      from:          'a@example.com',
      to:            'a@example.com',
      subject:       'com test 3',
      message_id:    'some@id_com_1',
      body:          'some message 123',
      internal:      false,
      sender:        Ticket::Article::Sender.find_by(name: 'Agent'),
      type:          Ticket::Article::Type.find_by(name: 'email'),
      updated_by_id: 1,
      created_by_id: 1,
      created_at:    '2017-04-13 09:00',
      updated_at:    '2017-04-13 09:00',
    )

    result = Stats::TicketWaitingTime.generate(user1)
    assert_equal(60, result[:handling_time])
    assert_equal('supergood', result[:state])
    assert_equal(140, result[:average_per_agent])
    assert_equal(1.0, result[:percent])

    travel_back

  end

end
