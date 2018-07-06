
require 'test_helper'

class TicketNumberTest < ActiveSupport::TestCase
  test 'number' do
    Setting.set('ticket_number_increment', { checksum: false, min_size: 5 })
    Setting.set('system_id', 1)

    number = Ticket::Number.generate
    assert_equal(number.to_s.length, 5)

    Setting.set('ticket_number_increment', { checksum: false, min_size: 10 })
    Setting.set('system_id', 1)

    number = Ticket::Number.generate
    assert_equal(number.to_s.length, 10)

    Setting.set('ticket_number_increment', { checksum: true, min_size: 5 })
    Setting.set('system_id', 1)

    number = Ticket::Number.generate
    assert_equal(number.to_s.length, 5)

    Setting.set('ticket_number_increment', { checksum: true, min_size: 10 })
    Setting.set('system_id', 1)

    number = Ticket::Number.generate
    assert_equal(number.to_s.length, 10)

    Setting.set('ticket_number_increment', { checksum: false, min_size: 5 })
    Setting.set('system_id', 88)

    number = Ticket::Number.generate
    assert_equal(number.to_s.length, 5)

    Setting.set('ticket_number_increment', { checksum: false, min_size: 10 })
    Setting.set('system_id', 88)

    number = Ticket::Number.generate
    assert_equal(number.to_s.length, 10)

    Setting.set('ticket_number_increment', { checksum: true, min_size: 5 })
    Setting.set('system_id', 88)

    number = Ticket::Number.generate
    assert_equal(number.to_s.length, 5)

    Setting.set('ticket_number_increment', { checksum: true, min_size: 10 })
    Setting.set('system_id', 88)

    number = Ticket::Number.generate
    assert_equal(number.to_s.length, 10)

    150.times do
      number = Ticket::Number.generate
      assert_equal(number.to_s.length, 10)
    end

  end

  test 'number check' do
    Setting.set('ticket_number_increment', { checksum: false, min_size: 5 })

    Setting.set('system_id', 1)

    ticket = Ticket.create!(
      title: 'test 1',
      group: Group.lookup(name: 'Users'),
      customer_id: 2,
      state: Ticket::State.lookup(name: 'new'),
      priority: Ticket::Priority.lookup(name: '2 normal'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    subject = ticket.subject_build(ticket.title)

    ticket_check = Ticket::Number.check(subject)
    assert_equal(ticket.id, ticket_check.id)

    Setting.set('system_id', 999)

    ticket_check = Ticket::Number.check(subject)
    assert_not(ticket_check)

    Setting.set('ticket_number_ignore_system_id', true)

    ticket_check = Ticket::Number.check(subject)
    assert_equal(ticket.id, ticket_check.id)
  end

  test 'date' do
    Setting.set('ticket_number', 'Ticket::Number::Date')
    Setting.set('ticket_number_date', { checksum: false })
    Setting.set('system_id', 1)
    system_id = Setting.get('system_id')
    number_prefix = "#{Time.zone.now.strftime('%Y%m%d')}#{system_id}"

    number = Ticket::Number.generate
    assert_equal(number.to_s.length, 13)
    assert_match(/#{number_prefix}/, number.to_s)

    Setting.set('ticket_number_date', { checksum: false })
    Setting.set('system_id', 88)

    number = Ticket::Number.generate
    system_id = Setting.get('system_id')
    number_prefix = "#{Time.zone.now.strftime('%Y%m%d')}#{system_id}"
    assert_equal(number.to_s.length, 14)
    assert_match(/#{number_prefix}/, number.to_s)

    Setting.set('ticket_number_date', { checksum: true })
    Setting.set('system_id', 1)

    number = Ticket::Number.generate
    system_id = Setting.get('system_id')
    number_prefix = "#{Time.zone.now.strftime('%Y%m%d')}#{system_id}"
    assert_equal(number.to_s.length, 14)
    assert_match(/#{number_prefix}/, number.to_s)

    Setting.set('ticket_number_date', { checksum: true })
    Setting.set('system_id', 88)

    number = Ticket::Number.generate
    system_id = Setting.get('system_id')
    number_prefix = "#{Time.zone.now.strftime('%Y%m%d')}#{system_id}"
    assert_equal(number.to_s.length, 15)
    assert_match(/#{number_prefix}/, number.to_s)

    150.times do
      number = Ticket::Number.generate
      assert_equal(number.to_s.length, 15)
    end

  end

  test 'date check' do
    Setting.set('ticket_number', 'Ticket::Number::Date')
    Setting.set('ticket_number_date', { checksum: false })

    Setting.set('system_id', 1)

    ticket = Ticket.create!(
      title: 'test 1',
      group: Group.lookup(name: 'Users'),
      customer_id: 2,
      state: Ticket::State.lookup(name: 'new'),
      priority: Ticket::Priority.lookup(name: '2 normal'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    subject = ticket.subject_build(ticket.title)

    ticket_check = Ticket::Number.check(subject)
    assert_equal(ticket.id, ticket_check.id)

    Setting.set('system_id', 999)

    ticket_check = Ticket::Number.check(subject)
    assert_not(ticket_check)

    Setting.set('ticket_number_ignore_system_id', true)

    ticket_check = Ticket::Number.check(subject)
    assert_equal(ticket.id, ticket_check.id)
  end

end
