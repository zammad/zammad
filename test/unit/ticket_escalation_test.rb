
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
    assert_in_delta((ticket_escalation_at - 30.minutes).to_i, ticket.escalation_at.to_i, 90)

    sla.destroy!
    calendar.destroy!

    ticket.save!
    assert_not(ticket.has_changes_to_save?)
    assert_not(ticket.escalation_at)

  end

  test 'email process and reply via email' do

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

    email = "From: Bob Smith <customer@example.com>
To: zammad@example.com
Subject: some value 123

Some Text"

    ticket_p, article_p, user_p, mail = Channel::EmailParser.new.process({}, email)
    ticket_p.reload
    assert(ticket_p.escalation_at)
    assert_in_delta(ticket_p.first_response_escalation_at.to_i, (ticket_p.created_at + 1.hour).to_i, 90)
    assert_in_delta(ticket_p.update_escalation_at.to_i, (ticket_p.created_at + 3.hours).to_i, 90)
    assert_in_delta(ticket_p.close_escalation_at.to_i, (ticket_p.created_at + 4.hours).to_i, 90)
    assert_in_delta(ticket_p.escalation_at.to_i, (ticket_p.created_at + 1.hour).to_i, 90)

    travel 3.hours
    article = nil

    ticket_p.with_lock do
      article = Ticket::Article.create!(
        ticket_id: ticket_p.id,
        from: 'some_sender@example.com',
        to: 'some_recipient@example.com',
        subject: 'some subject',
        message_id: 'some@id',
        body: 'some message',
        internal: false,
        sender: Ticket::Article::Sender.where(name: 'Agent').first,
        type: Ticket::Article::Type.where(name: 'email').first,
        updated_by_id: 1,
        created_by_id: 1,
      )
    end

    ticket_p.reload
    assert_in_delta(ticket_p.first_response_escalation_at.to_i, (ticket_p.created_at + 1.hour).to_i, 90)
    assert_in_delta(ticket_p.update_escalation_at.to_i, (ticket_p.last_contact_agent_at + 3.hours).to_i, 90)
    assert_in_delta(ticket_p.close_escalation_at.to_i, (ticket_p.created_at + 4.hours).to_i, 90)
    assert_in_delta(ticket_p.escalation_at.to_i, (ticket_p.created_at + 4.hours).to_i, 90)

  end
end
