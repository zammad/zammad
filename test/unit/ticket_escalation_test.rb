
require 'test_helper'

class TicketEscalationTest < ActiveSupport::TestCase
  test 'ticket create' do
    ticket = Ticket.new(
      title: 'some value 123',
      group: Group.lookup(name: 'Users'),
      customer_id: 2,
      updated_by_id: 1,
      created_by_id: 1,
    )
    ticket.save!
    assert(ticket, 'ticket created')
    assert_not(ticket.escalation_at)
    assert_not(ticket.has_changes_to_save?)

    article = Ticket::Article.create!(
      ticket_id: ticket.id,
      type_id: Ticket::Article::Type.find_by(name: 'note').id,
      sender_id: Ticket::Article::Sender.find_by(name: 'Customer').id,
      body: 'some body',
      internal: false,
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert_not(article.has_changes_to_save?)
    assert_not(ticket.has_changes_to_save?)

    calendar = Calendar.create_or_update(
      name: 'Escalation Test',
      timezone: 'Europe/Berlin',
      business_hours: {
        mon: {
          active: true,
          timeframes: [ ['00:00', '23:59'] ]
        },
        tue: {
          active: true,
          timeframes: [ ['00:00', '23:59'] ]
        },
        wed: {
          active: true,
          timeframes: [ ['00:00', '23:59'] ]
        },
        thu: {
          active: true,
          timeframes: [ ['00:00', '23:59'] ]
        },
        fri: {
          active: true,
          timeframes: [ ['00:00', '23:59'] ]
        },
        sat: {
          active: true,
          timeframes: [ ['00:00', '23:59'] ]
        },
        sun: {
          active: true,
          timeframes: [ ['00:00', '23:59'] ]
        },
      },
      default: true,
      ical_url: nil,
      updated_by_id: 1,
      created_by_id: 1,
    )

    sla = Sla.create_or_update(
      name: 'test sla 1',
      condition: {
        'ticket.title' => {
          operator: 'contains',
          value: 'some value 123',
        },
      },
      first_response_time: 60,
      update_time: 180,
      solution_time: 240,
      calendar_id: calendar.id,
      updated_by_id: 1,
      created_by_id: 1,
    )

    ticket = Ticket.new(
      title: 'some value 123',
      group: Group.lookup(name: 'Users'),
      customer_id: 2,
      updated_by_id: 1,
      created_by_id: 1,
    )
    ticket.save!
    assert(ticket, 'ticket created')
    ticket_escalation_at = ticket.escalation_at
    assert(ticket.escalation_at)
    assert_not(ticket.has_changes_to_save?)

    article = Ticket::Article.create!(
      ticket_id: ticket.id,
      type_id: Ticket::Article::Type.find_by(name: 'note').id,
      sender_id: Ticket::Article::Sender.find_by(name: 'Customer').id,
      body: 'some body',
      internal: false,
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert_not(article.has_changes_to_save?)
    assert_not(ticket.has_changes_to_save?)

    travel 1.second

    sla.first_response_time = 30
    sla.save!

    ticket.save!
    assert_not(ticket.has_changes_to_save?)
    assert(ticket.escalation_at)
    assert_equal(ticket_escalation_at.to_s, ticket.escalation_at.to_s)

    ticket.title = 'some value 123-1'
    ticket.save!
    assert_not(ticket.has_changes_to_save?)

    assert(ticket.escalation_at)
    assert_not_equal(ticket_escalation_at.to_s, ticket.escalation_at.to_s)

    sla.destroy!
    calendar.destroy!

    ticket.save!
    assert_not(ticket.has_changes_to_save?)
    assert(ticket.escalation_at)

    ticket.title = 'some value 123-2'
    ticket.save!
    assert_not(ticket.has_changes_to_save?)
    assert_not(ticket.escalation_at)

  end

end
