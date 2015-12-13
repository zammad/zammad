# encoding: utf-8
require 'test_helper'

class TicketSlaTest < ActiveSupport::TestCase

  test 'ticket sla' do

    # cleanup
    delete = Sla.destroy_all
    assert( delete, 'sla destroy_all' )
    delete = Ticket.destroy_all
    assert( delete, 'ticket destroy_all' )

    ticket = Ticket.create(
      title: 'some title äöüß',
      group: Group.lookup( name: 'Users'),
      customer_id: 2,
      state: Ticket::State.lookup( name: 'new' ),
      priority: Ticket::Priority.lookup( name: '2 normal' ),
      created_at: '2013-03-21 09:30:00 UTC',
      updated_at: '2013-03-21 09:30:00 UTC',
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert( ticket, 'ticket created' )
    assert_equal( ticket.escalation_time, nil, 'ticket.escalation_time verify' )

    calendar1 = Calendar.create_or_update(
      name: 'EU 1',
      timezone: 'Europe/Berlin',
      business_hours: {
        mon: {
          active: true,
          timeframes: [ ['09:00', '17:00'] ]
        },
        tue: {
          active: true,
          timeframes: [ ['09:00', '17:00'] ]
        },
        wed: {
          active: true,
          timeframes: [ ['09:00', '17:00'] ]
        },
        thu: {
          active: true,
          timeframes: [ ['09:00', '17:00'] ]
        },
        fri: {
          active: true,
          timeframes: [ ['09:00', '17:00'] ]
        },
        sat: {
          active: false,
          timeframes: [ ['08:00', '17:00'] ]
        },
        sun: {
          active: false,
          timeframes: [ ['08:00', '17:00'] ]
        },
      },
      default: true,
      ical_url: nil,
      updated_by_id: 1,
      created_by_id: 1,
    )

    sla = Sla.create_or_update(
      name: 'test sla 1',
      condition: {},
      first_response_time: 60,
      update_time: 180,
      solution_time: 240,
      calendar_id: calendar1.id,
      updated_by_id: 1,
      created_by_id: 1,
    )
    #puts Delayed::Job.all.inspect
    Delayed::Worker.new.work_off
    ticket = Ticket.find(ticket.id)
    assert_equal( ticket.escalation_time.gmtime.to_s, '2013-03-21 10:30:00 UTC', 'ticket.escalation_time verify 1' )
    assert_equal( ticket.first_response_escal_date.gmtime.to_s, '2013-03-21 10:30:00 UTC', 'ticket.first_response_escal_date verify 1' )
    assert_equal( ticket.update_time_escal_date.gmtime.to_s, '2013-03-21 12:30:00 UTC', 'ticket.update_time_escal_date verify 1' )
    assert_equal( ticket.close_time_escal_date.gmtime.to_s, '2013-03-21 13:30:00 UTC', 'ticket.close_time_escal_date verify 1' )

    sla = Sla.create_or_update(
      name: 'test sla 1',
      condition: {},
      first_response_time: 120,
      update_time: 180,
      solution_time: 240,
      calendar_id: calendar1.id,
      updated_by_id: 1,
      created_by_id: 1,
    )
    #puts Delayed::Job.all.inspect
    Delayed::Worker.new.work_off
    ticket = Ticket.find(ticket.id)
    assert_equal( ticket.escalation_time.gmtime.to_s, '2013-03-21 11:30:00 UTC', 'ticket.escalation_time verify 1' )
    assert_equal( ticket.first_response_escal_date.gmtime.to_s, '2013-03-21 11:30:00 UTC', 'ticket.first_response_escal_date verify 1' )
    assert_equal( ticket.update_time_escal_date.gmtime.to_s, '2013-03-21 12:30:00 UTC', 'ticket.update_time_escal_date verify 1' )
    assert_equal( ticket.close_time_escal_date.gmtime.to_s, '2013-03-21 13:30:00 UTC', 'ticket.close_time_escal_date verify 1' )
    delete = sla.destroy
    assert( delete, 'sla destroy 1' )

    calendar2 = Calendar.create_or_update(
      name: 'EU 2',
      timezone: 'Europe/Berlin',
      business_hours: {
        mon: {
          active: true,
          timeframes: [ ['08:00', '18:00'] ]
        },
        tue: {
          active: true,
          timeframes: [ ['08:00', '18:00'] ]
        },
        wed: {
          active: true,
          timeframes: [ ['08:00', '18:00'] ]
        },
        thu: {
          active: true,
          timeframes: [ ['08:00', '18:00'] ]
        },
        fri: {
          active: true,
          timeframes: [ ['08:00', '18:00'] ]
        },
        sat: {
          active: false,
          timeframes: [ ['08:00', '17:00'] ]
        },
        sun: {
          active: false,
          timeframes: [ ['08:00', '17:00'] ]
        },
      },
      default: true,
      ical_url: nil,
      updated_by_id: 1,
      created_by_id: 1,
    )
    sla = Sla.create_or_update(
      name: 'test sla 2',
      condition: {
        'ticket.priority_id' => {
          operator: 'is',
          value: %w(1 2 3),
        },
      },
      calendar_id: calendar2.id,
      first_response_time: 60,
      update_time: 120,
      solution_time: 180,
      updated_by_id: 1,
      created_by_id: 1,
    )
    #puts Delayed::Job.all.inspect
    Delayed::Worker.new.work_off
    ticket = Ticket.find(ticket.id)
    assert_equal( ticket.escalation_time.gmtime.to_s, '2013-03-21 10:30:00 UTC', 'ticket.escalation_time verify 2' )
    assert_equal( ticket.first_response_escal_date.gmtime.to_s, '2013-03-21 10:30:00 UTC', 'ticket.first_response_escal_date verify 2' )
    assert_equal( ticket.first_response, nil, 'ticket.first_response verify 2' )
    assert_equal( ticket.first_response_in_min, nil, 'ticket.first_response_in_min verify 2' )
    assert_equal( ticket.first_response_diff_in_min, nil, 'ticket.first_response_diff_in_min verify 2' )

    assert_equal( ticket.update_time_escal_date.gmtime.to_s, '2013-03-21 11:30:00 UTC', 'ticket.update_time_escal_date verify 2' )
    assert_equal( ticket.update_time_in_min, nil, 'ticket.update_time_in_min verify 2' )
    assert_equal( ticket.update_time_diff_in_min, nil, 'ticket.update_time_diff_in_min verify 2' )

    assert_equal( ticket.close_time_escal_date.gmtime.to_s, '2013-03-21 12:30:00 UTC', 'ticket.close_time_escal_date verify 2' )
    assert_equal( ticket.close_time_in_min, nil, 'ticket.close_time_in_min verify 2' )
    assert_equal( ticket.close_time_diff_in_min, nil, 'ticket.close_time_diff_in_min verify 2' )

    # set first response in time
    ticket.update_attributes(
      first_response: '2013-03-21 10:00:00 UTC',
    )

    assert_equal( ticket.escalation_time.gmtime.to_s, '2013-03-21 11:30:00 UTC', 'ticket.escalation_time verify 3' )
    assert_equal( ticket.first_response_escal_date.gmtime.to_s, '2013-03-21 10:30:00 UTC', 'ticket.first_response_escal_date verify 3' )
    assert_equal( ticket.first_response.gmtime.to_s, '2013-03-21 10:00:00 UTC', 'ticket.first_response verify 3' )
    assert_equal( ticket.first_response_in_min, 30, 'ticket.first_response_in_min verify 3' )
    assert_equal( ticket.first_response_diff_in_min, 30, 'ticket.first_response_diff_in_min verify 3' )

    assert_equal( ticket.update_time_escal_date.gmtime.to_s, '2013-03-21 11:30:00 UTC', 'ticket.update_time_escal_date verify 3' )
    assert_equal( ticket.update_time_in_min, nil, 'ticket.update_time_in_min verify 3' )
    assert_equal( ticket.update_time_diff_in_min, nil, 'ticket.update_time_diff_in_min verify 3' )

    assert_equal( ticket.close_time_escal_date.gmtime.to_s, '2013-03-21 12:30:00 UTC', 'ticket.close_time_escal_date verify 3' )
    assert_equal( ticket.close_time_in_min, nil, 'ticket.close_time_in_min verify 3' )
    assert_equal( ticket.close_time_diff_in_min, nil, 'ticket.close_time_diff_in_min verify 3' )

    # set first reponse over time
    ticket.update_attributes(
      first_response: '2013-03-21 14:00:00 UTC',
    )

    assert_equal( ticket.escalation_time.gmtime.to_s, '2013-03-21 11:30:00 UTC', 'ticket.escalation_time verify 4' )
    assert_equal( ticket.first_response_escal_date.gmtime.to_s, '2013-03-21 10:30:00 UTC', 'ticket.first_response_escal_date verify 4' )
    assert_equal( ticket.first_response.gmtime.to_s, '2013-03-21 14:00:00 UTC', 'ticket.first_response verify 4' )
    assert_equal( ticket.first_response_in_min, 270, 'ticket.first_response_in_min verify 4' )
    assert_equal( ticket.first_response_diff_in_min, -210, 'ticket.first_response_diff_in_min verify 4' )

    assert_equal( ticket.update_time_escal_date.gmtime.to_s, '2013-03-21 11:30:00 UTC', 'ticket.update_time_escal_date verify 4' )
    assert_equal( ticket.update_time_in_min, nil, 'ticket.update_time_in_min verify 4' )
    assert_equal( ticket.update_time_diff_in_min, nil, 'ticket.update_time_diff_in_min verify 4' )

    assert_equal( ticket.close_time_escal_date.gmtime.to_s, '2013-03-21 12:30:00 UTC', 'ticket.close_time_escal_date verify 4' )
    assert_equal( ticket.close_time_in_min, nil, 'ticket.close_time_in_min verify 4' )
    assert_equal( ticket.close_time_diff_in_min, nil, 'ticket.close_time_diff_in_min verify 4' )

    # set update time in time
    ticket.update_attributes(
      last_contact_agent: '2013-03-21 11:00:00 UTC',
    )
    assert_equal( ticket.escalation_time.gmtime.to_s, '2013-03-21 12:30:00 UTC', 'ticket.escalation_time verify 5' )

    assert_equal( ticket.first_response_escal_date.gmtime.to_s, '2013-03-21 10:30:00 UTC', 'ticket.first_response_escal_date verify 5' )
    assert_equal( ticket.first_response.gmtime.to_s, '2013-03-21 14:00:00 UTC', 'ticket.first_response verify 5' )
    assert_equal( ticket.first_response_in_min, 270, 'ticket.first_response_in_min verify 5' )
    assert_equal( ticket.first_response_diff_in_min, -210, 'ticket.first_response_diff_in_min verify 5' )

    assert_equal( ticket.update_time_escal_date.gmtime.to_s, '2013-03-21 13:00:00 UTC', 'ticket.update_time_escal_date verify 5' )
    assert_equal( ticket.update_time_in_min, 90, 'ticket.update_time_in_min verify 5' )
    assert_equal( ticket.update_time_diff_in_min, 30, 'ticket.update_time_diff_in_min verify 5' )

    assert_equal( ticket.close_time_escal_date.gmtime.to_s, '2013-03-21 12:30:00 UTC', 'ticket.close_time_escal_date verify 5' )
    assert_equal( ticket.close_time_in_min, nil, 'ticket.close_time_in_min verify 5' )
    assert_equal( ticket.close_time_diff_in_min, nil, 'ticket.close_time_diff_in_min verify 5' )

    # set update time over time
    ticket.update_attributes(
      last_contact_agent: '2013-03-21 12:00:00 UTC',
    )
    assert_equal( ticket.escalation_time.gmtime.to_s, '2013-03-21 12:30:00 UTC', 'ticket.escalation_time verify 6' )

    assert_equal( ticket.first_response_escal_date.gmtime.to_s, '2013-03-21 10:30:00 UTC', 'ticket.first_response_escal_date verify 6' )
    assert_equal( ticket.first_response.gmtime.to_s, '2013-03-21 14:00:00 UTC', 'ticket.first_response verify 6' )
    assert_equal( ticket.first_response_in_min, 270, 'ticket.first_response_in_min verify 6' )
    assert_equal( ticket.first_response_diff_in_min, -210, 'ticket.first_response_diff_in_min verify 6' )

    assert_equal( ticket.update_time_escal_date.gmtime.to_s, '2013-03-21 14:00:00 UTC', 'ticket.update_time_escal_date verify 6' )
    assert_equal( ticket.update_time_in_min, 150, 'ticket.update_time_in_min verify 6' )
    assert_equal( ticket.update_time_diff_in_min, -30, 'ticket.update_time_diff_in_min verify 6' )

    assert_equal( ticket.close_time_escal_date.gmtime.to_s, '2013-03-21 12:30:00 UTC', 'ticket.close_time_escal_date verify 6' )
    assert_equal( ticket.close_time_in_min, nil, 'ticket.close_time_in_min verify 6' )
    assert_equal( ticket.close_time_diff_in_min, nil, 'ticket.close_time_diff_in_min verify 6' )

    # set update time over time
    ticket.update_attributes(
      last_contact_customer: '2013-03-21 12:05:00 UTC',
    )
    assert_equal( ticket.escalation_time.gmtime.to_s, '2013-03-21 12:30:00 UTC', 'ticket.escalation_time verify 6' )

    assert_equal( ticket.first_response_escal_date.gmtime.to_s, '2013-03-21 10:30:00 UTC', 'ticket.first_response_escal_date verify 6' )
    assert_equal( ticket.first_response.gmtime.to_s, '2013-03-21 14:00:00 UTC', 'ticket.first_response verify 6' )
    assert_equal( ticket.first_response_in_min, 270, 'ticket.first_response_in_min verify 6' )
    assert_equal( ticket.first_response_diff_in_min, -210, 'ticket.first_response_diff_in_min verify 6' )

    assert_equal( ticket.update_time_escal_date.gmtime.to_s, '2013-03-21 14:05:00 UTC', 'ticket.update_time_escal_date verify 6' )
    assert_equal( ticket.update_time_in_min, 155, 'ticket.update_time_in_min verify 6' )
    assert_equal( ticket.update_time_diff_in_min, -35, 'ticket.update_time_diff_in_min verify 6' )

    assert_equal( ticket.close_time_escal_date.gmtime.to_s, '2013-03-21 12:30:00 UTC', 'ticket.close_time_escal_date verify 6' )
    assert_equal( ticket.close_time_in_min, nil, 'ticket.close_time_in_min verify 6' )
    assert_equal( ticket.close_time_diff_in_min, nil, 'ticket.close_time_diff_in_min verify 6' )

    # set update time over time
    ticket.update_attributes(
      last_contact_agent: '2013-03-21 12:10:00 UTC',
    )
    assert_equal( ticket.escalation_time.gmtime.to_s, '2013-03-21 12:30:00 UTC', 'ticket.escalation_time verify 6' )

    assert_equal( ticket.first_response_escal_date.gmtime.to_s, '2013-03-21 10:30:00 UTC', 'ticket.first_response_escal_date verify 6' )
    assert_equal( ticket.first_response.gmtime.to_s, '2013-03-21 14:00:00 UTC', 'ticket.first_response verify 6' )
    assert_equal( ticket.first_response_in_min, 270, 'ticket.first_response_in_min verify 6' )
    assert_equal( ticket.first_response_diff_in_min, -210, 'ticket.first_response_diff_in_min verify 6' )

    assert_equal( ticket.update_time_escal_date.gmtime.to_s, '2013-03-21 14:10:00 UTC', 'ticket.update_time_escal_date verify 6' )
    assert_equal( ticket.update_time_in_min, 160, 'ticket.update_time_in_min verify 6' )
    assert_equal( ticket.update_time_diff_in_min, -40, 'ticket.update_time_diff_in_min verify 6' )

    assert_equal( ticket.close_time_escal_date.gmtime.to_s, '2013-03-21 12:30:00 UTC', 'ticket.close_time_escal_date verify 6' )
    assert_equal( ticket.close_time_in_min, nil, 'ticket.close_time_in_min verify 6' )
    assert_equal( ticket.close_time_diff_in_min, nil, 'ticket.close_time_diff_in_min verify 6' )

    # set close time in time
    ticket.update_attributes(
      close_time: '2013-03-21 11:30:00 UTC',
    )
    assert_equal( ticket.escalation_time.gmtime.to_s, '2013-03-21 14:10:00 UTC', 'ticket.escalation_time verify 7' )

    assert_equal( ticket.first_response_escal_date.gmtime.to_s, '2013-03-21 10:30:00 UTC', 'ticket.first_response_escal_date verify 7' )
    assert_equal( ticket.first_response.gmtime.to_s, '2013-03-21 14:00:00 UTC', 'ticket.first_response verify 7' )
    assert_equal( ticket.first_response_in_min, 270, 'ticket.first_response_in_min verify 7' )
    assert_equal( ticket.first_response_diff_in_min, -210, 'ticket.first_response_diff_in_min verify 7' )

    assert_equal( ticket.update_time_escal_date.gmtime.to_s, '2013-03-21 14:10:00 UTC', 'ticket.update_time_escal_date verify 7' )
    assert_equal( ticket.update_time_in_min, 160, 'ticket.update_time_in_min verify 7' )
    assert_equal( ticket.update_time_diff_in_min, -40, 'ticket.update_time_diff_in_min verify 7' )

    assert_equal( ticket.close_time_escal_date.gmtime.to_s, '2013-03-21 12:30:00 UTC', 'ticket.close_time_escal_date verify 7' )
    assert_equal( ticket.close_time_in_min, 120, 'ticket.close_time_in_min verify 7' )
    assert_equal( ticket.close_time_diff_in_min, 60, 'ticket.close_time_diff_in_min verify 7' )

    # set close time over time
    ticket.update_attributes(
      close_time: '2013-03-21 13:00:00 UTC',
    )
    assert_equal( ticket.escalation_time.gmtime.to_s, '2013-03-21 14:10:00 UTC', 'ticket.escalation_time verify 8' )

    assert_equal( ticket.first_response_escal_date.gmtime.to_s, '2013-03-21 10:30:00 UTC', 'ticket.first_response_escal_date verify 8' )
    assert_equal( ticket.first_response.gmtime.to_s, '2013-03-21 14:00:00 UTC', 'ticket.first_response verify 8' )
    assert_equal( ticket.first_response_in_min, 270, 'ticket.first_response_in_min verify 8' )
    assert_equal( ticket.first_response_diff_in_min, -210, 'ticket.first_response_diff_in_min verify 8' )

    assert_equal( ticket.update_time_escal_date.gmtime.to_s, '2013-03-21 14:10:00 UTC', 'ticket.update_time_escal_date verify 8' )
    assert_equal( ticket.update_time_in_min, 160, 'ticket.update_time_in_min verify 8' )
    assert_equal( ticket.update_time_diff_in_min, -40, 'ticket.update_time_diff_in_min verify 8' )

    assert_equal( ticket.close_time_escal_date.gmtime.to_s, '2013-03-21 12:30:00 UTC', 'ticket.close_time_escal_date verify 8' )
    assert_equal( ticket.close_time_in_min, 210, 'ticket.close_time_in_min verify 8' )
    assert_equal( ticket.close_time_diff_in_min, -30, 'ticket.close_time_diff_in_min verify 8' )

    # set close time over time
    ticket.update_attributes(
      state: Ticket::State.lookup( name: 'closed' )
    )
    assert_equal( ticket.escalation_time, nil, 'ticket.escalation_time verify 9' )

    assert_equal( ticket.first_response_escal_date.gmtime.to_s, '2013-03-21 10:30:00 UTC', 'ticket.first_response_escal_date verify 9' )
    assert_equal( ticket.first_response.gmtime.to_s, '2013-03-21 14:00:00 UTC', 'ticket.first_response verify 9' )
    assert_equal( ticket.first_response_in_min, 270, 'ticket.first_response_in_min verify 9' )
    assert_equal( ticket.first_response_diff_in_min, -210, 'ticket.first_response_diff_in_min verify 9' )

    assert_equal( ticket.update_time_escal_date.gmtime.to_s, '2013-03-21 14:10:00 UTC', 'ticket.update_time_escal_date verify 9' )
    assert_equal( ticket.update_time_in_min, 160, 'ticket.update_time_in_min verify 9' )
    assert_equal( ticket.update_time_diff_in_min, -40, 'ticket.update_time_diff_in_min verify 9' )

    assert_equal( ticket.close_time_escal_date.gmtime.to_s, '2013-03-21 12:30:00 UTC', 'ticket.close_time_escal_date verify 9' )
    assert_equal( ticket.close_time_in_min, 210, 'ticket.close_time_in_min verify 9' )
    assert_equal( ticket.close_time_diff_in_min, -30, 'ticket.close_time_diff_in_min verify 9' )

    delete = ticket.destroy
    assert( delete, 'ticket destroy' )

    ticket = Ticket.create(
      title: 'some title äöüß',
      group: Group.lookup( name: 'Users'),
      customer_id: 2,
      state: Ticket::State.lookup( name: 'new' ),
      priority: Ticket::Priority.lookup( name: '2 normal' ),
      updated_by_id: 1,
      created_by_id: 1,
      created_at: '2013-03-28 23:49:00 UTC',
      updated_at: '2013-03-28 23:49:00 UTC',
    )
    assert( ticket, 'ticket created' )

    assert_equal( ticket.title, 'some title äöüß', 'ticket.title verify' )
    assert_equal( ticket.group.name, 'Users', 'ticket.group verify' )
    assert_equal( ticket.state.name, 'new', 'ticket.state verify' )

    # create inbound article
    article_inbound = Ticket::Article.create(
      ticket_id: ticket.id,
      from: 'some_sender@example.com',
      to: 'some_recipient@example.com',
      subject: 'some subject',
      message_id: 'some@id',
      body: 'some message',
      internal: false,
      sender: Ticket::Article::Sender.where(name: 'Customer').first,
      type: Ticket::Article::Type.where(name: 'email').first,
      updated_by_id: 1,
      created_by_id: 1,
      created_at: '2013-03-28 23:49:00 UTC',
      updated_at: '2013-03-28 23:49:00 UTC',
    )
    ticket = Ticket.find(ticket.id)
    assert_equal( ticket.article_count, 1, 'ticket.article_count verify - inbound' )
    assert_equal( ticket.last_contact.to_s, article_inbound.created_at.to_s, 'ticket.last_contact verify - inbound' )
    assert_equal( ticket.last_contact_customer.to_s, article_inbound.created_at.to_s, 'ticket.last_contact_customer verify - inbound' )
    assert_equal( ticket.last_contact_agent, nil, 'ticket.last_contact_agent verify - inbound' )
    assert_equal( ticket.first_response, nil, 'ticket.first_response verify - inbound' )
    assert_equal( ticket.close_time, nil, 'ticket.close_time verify - inbound' )

    # create outbound article
    article_outbound = Ticket::Article.create(
      ticket_id: ticket.id,
      from: 'some_recipient@example.com',
      to: 'some_sender@example.com',
      subject: 'some subject',
      message_id: 'some@id2',
      body: 'some message 2',
      internal: false,
      sender: Ticket::Article::Sender.where(name: 'Agent').first,
      type: Ticket::Article::Type.where(name: 'email').first,
      updated_by_id: 1,
      created_by_id: 1,
      created_at: '2013-03-29 07:00:03 UTC',
      updated_at: '2013-03-29 07:00:03 UTC',
    )

    ticket = Ticket.find(ticket.id)
    assert_equal( ticket.article_count, 2, 'ticket.article_count verify - outbound' )
    assert_equal( ticket.last_contact.to_s, article_outbound.created_at.to_s, 'ticket.last_contact verify - outbound' )
    assert_equal( ticket.last_contact_customer.to_s, article_inbound.created_at.to_s, 'ticket.last_contact_customer verify - outbound' )
    assert_equal( ticket.last_contact_agent.to_s, article_outbound.created_at.to_s, 'ticket.last_contact_agent verify - outbound' )
    assert_equal( ticket.first_response.to_s, article_outbound.created_at.to_s, 'ticket.first_response verify - outbound' )
    assert_equal( ticket.first_response_in_min, 0, 'ticket.first_response_in_min verify - outbound' )
    assert_equal( ticket.first_response_diff_in_min, 60, 'ticket.first_response_diff_in_min verify - outbound' )
    assert_equal( ticket.close_time, nil, 'ticket.close_time verify - outbound' )

    delete = ticket.destroy
    assert( delete, 'ticket destroy' )

    ticket = Ticket.create(
      title: 'some title äöüß',
      group: Group.lookup( name: 'Users'),
      customer_id: 2,
      state: Ticket::State.lookup( name: 'new' ),
      priority: Ticket::Priority.lookup( name: '2 normal' ),
      updated_by_id: 1,
      created_by_id: 1,
      created_at: '2013-03-28 23:49:00 UTC',
      updated_at: '2013-03-28 23:49:00 UTC',
    )
    assert( ticket, 'ticket created' )

    assert_equal( ticket.title, 'some title äöüß', 'ticket.title verify' )
    assert_equal( ticket.group.name, 'Users', 'ticket.group verify' )
    assert_equal( ticket.state.name, 'new', 'ticket.state verify' )

    # create inbound article
    article_inbound = Ticket::Article.create(
      ticket_id: ticket.id,
      from: 'some_sender@example.com',
      subject: 'some subject',
      message_id: 'some@id',
      body: 'some message',
      internal: false,
      sender: Ticket::Article::Sender.where(name: 'Customer').first,
      type: Ticket::Article::Type.where(name: 'phone').first,
      updated_by_id: 1,
      created_by_id: 1,
      created_at: '2013-03-28 23:49:00 UTC',
      updated_at: '2013-03-28 23:49:00 UTC',
    )
    ticket = Ticket.find(ticket.id)
    assert_equal( ticket.article_count, 1, 'ticket.article_count verify - inbound' )
    assert_equal( ticket.last_contact.to_s, article_inbound.created_at.to_s, 'ticket.last_contact verify - inbound' )
    assert_equal( ticket.last_contact_customer.to_s, article_inbound.created_at.to_s, 'ticket.last_contact_customer verify - inbound' )
    assert_equal( ticket.last_contact_agent, nil, 'ticket.last_contact_agent verify - inbound' )
    assert_equal( ticket.first_response, nil, 'ticket.first_response verify - inbound' )
    assert_equal( ticket.close_time, nil, 'ticket.close_time verify - inbound' )

    # create note article
    article_note = Ticket::Article.create(
      ticket_id: ticket.id,
      from: 'some_sender@example.com',
      subject: 'some subject',
      message_id: 'some@id',
      body: 'some message',
      internal: false,
      sender: Ticket::Article::Sender.where(name: 'Agent').first,
      type: Ticket::Article::Type.where(name: 'note').first,
      updated_by_id: 1,
      created_by_id: 1,
      created_at: '2013-03-28 23:52:00 UTC',
      updated_at: '2013-03-28 23:52:00 UTC',
    )
    ticket = Ticket.find(ticket.id)
    assert_equal( ticket.article_count, 2, 'ticket.article_count verify - inbound' )
    assert_equal( ticket.last_contact.to_s, article_inbound.created_at.to_s, 'ticket.last_contact verify - inbound' )
    assert_equal( ticket.last_contact_customer.to_s, article_inbound.created_at.to_s, 'ticket.last_contact_customer verify - inbound' )
    assert_equal( ticket.last_contact_agent, nil, 'ticket.last_contact_agent verify - inbound' )
    assert_equal( ticket.first_response, nil, 'ticket.first_response verify - inbound' )
    assert_equal( ticket.close_time, nil, 'ticket.close_time verify - inbound' )

    # create outbound article
    article_outbound = Ticket::Article.create(
      ticket_id: ticket.id,
      from: 'some_sender@example.com',
      subject: 'some subject',
      message_id: 'some@id',
      body: 'some message',
      internal: false,
      sender: Ticket::Article::Sender.where(name: 'Agent').first,
      type: Ticket::Article::Type.where(name: 'phone').first,
      updated_by_id: 1,
      created_by_id: 1,
      created_at: '2013-03-28 23:55:00 UTC',
      updated_at: '2013-03-28 23:55:00 UTC',
    )
    ticket = Ticket.find(ticket.id)
    assert_equal( ticket.article_count, 3, 'ticket.article_count verify - inbound' )
    assert_equal( ticket.last_contact.to_s, article_outbound.created_at.to_s, 'ticket.last_contact verify - inbound' )
    assert_equal( ticket.last_contact_customer.to_s, article_inbound.created_at.to_s, 'ticket.last_contact_customer verify - inbound' )
    assert_equal( ticket.last_contact_agent.to_s, article_outbound.created_at.to_s, 'ticket.last_contact_agent verify - inbound' )
    assert_equal( ticket.first_response.to_s, article_outbound.created_at.to_s, 'ticket.first_response verify - inbound' )
    assert_equal( ticket.close_time, nil, 'ticket.close_time verify - inbound' )

    delete = sla.destroy
    assert( delete, 'sla destroy' )

    delete = sla.destroy
    assert( delete, 'sla destroy' )
  end

  test 'ticket sla + timezone + holiday' do

    # cleanup
    delete = Sla.destroy_all
    assert( delete, 'sla destroy_all' )
    delete = Ticket.destroy_all
    assert( delete, 'ticket destroy_all' )

    ticket = Ticket.create(
      title: 'some title äöüß',
      group: Group.lookup( name: 'Users'),
      customer_id: 2,
      state: Ticket::State.lookup( name: 'new' ),
      priority: Ticket::Priority.lookup( name: '2 normal' ),
      created_at: '2013-03-21 09:30:00 UTC',
      updated_at: '2013-03-21 09:30:00 UTC',
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert( ticket, 'ticket created' )
    assert_equal( ticket.escalation_time, nil, 'ticket.escalation_time verify' )

    # set sla's for timezone "Europe/Berlin" wintertime (+1), so UTC times are 7:00-16:00
    calendar = Calendar.create_or_update(
      name: 'EU 3',
      timezone: 'Europe/Berlin',
      business_hours: {
        mon: {
          active: true,
          timeframes: [ ['08:00', '17:00'] ]
        },
        tue: {
          active: true,
          timeframes: [ ['08:00', '17:00'] ]
        },
        wed: {
          active: true,
          timeframes: [ ['08:00', '17:00'] ]
        },
        thu: {
          active: true,
          timeframes: [ ['08:00', '17:00'] ]
        },
        fri: {
          active: true,
          timeframes: [ ['08:00', '17:00'] ]
        },
        sat: {
          active: true,
          timeframes: [ ['08:00', '17:00'] ]
        },
        sun: {
          active: true,
          timeframes: [ ['08:00', '17:00'] ]
        },
      },
      default: true,
      ical_url: nil,
      updated_by_id: 1,
      created_by_id: 1,
    )
    sla = Sla.create_or_update(
      name: 'aaa should not match',
      condition: {
        'ticket.priority_id' => {
          operator: 'is not',
          value: %w(1 2 3),
        },
      },
      calendar_id: calendar.id,
      first_response_time: 10,
      update_time: 20,
      solution_time: 300,
      updated_by_id: 1,
      created_by_id: 1,
    )
    sla = Sla.create_or_update(
      name: 'test sla 3',
      condition: {
        'ticket.priority_id' => {
          operator: 'is not',
          value: '1',
        },
      },
      calendar_id: calendar.id,
      first_response_time: 120,
      update_time: 180,
      solution_time: 240,
      updated_by_id: 1,
      created_by_id: 1,
    )
    #puts Delayed::Job.all.inspect
    Delayed::Worker.new.work_off
    ticket = Ticket.find(ticket.id)
    assert_equal( ticket.escalation_time.gmtime.to_s, '2013-03-21 11:30:00 UTC', 'ticket.escalation_time verify 1' )
    assert_equal( ticket.first_response_escal_date.gmtime.to_s, '2013-03-21 11:30:00 UTC', 'ticket.first_response_escal_date verify 1' )
    assert_equal( ticket.update_time_escal_date.gmtime.to_s, '2013-03-21 12:30:00 UTC', 'ticket.update_time_escal_date verify 1' )
    assert_equal( ticket.close_time_escal_date.gmtime.to_s, '2013-03-21 13:30:00 UTC', 'ticket.close_time_escal_date verify 1' )

    delete = sla.destroy
    assert( delete, 'sla destroy' )

    delete = ticket.destroy
    assert( delete, 'ticket destroy' )
    ticket = Ticket.create(
      title: 'some title äöüß',
      group: Group.lookup( name: 'Users'),
      customer_id: 2,
      state: Ticket::State.lookup( name: 'new' ),
      priority: Ticket::Priority.lookup( name: '2 normal' ),
      created_at: '2013-10-21 09:30:00 UTC',
      updated_at: '2013-10-21 09:30:00 UTC',
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert( ticket, 'ticket created' )
    assert_equal( ticket.escalation_time, nil, 'ticket.escalation_time verify' )

    # set sla's for timezone "Europe/Berlin" summertime (+2), so UTC times are 6:00-15:00
    calendar = Calendar.create_or_update(
      name: 'EU 4',
      timezone: 'Europe/Berlin',
      business_hours: {
        mon: {
          active: true,
          timeframes: [ ['08:00', '17:00'] ]
        },
        tue: {
          active: true,
          timeframes: [ ['08:00', '17:00'] ]
        },
        wed: {
          active: true,
          timeframes: [ ['08:00', '17:00'] ]
        },
        thu: {
          active: true,
          timeframes: [ ['08:00', '17:00'] ]
        },
        fri: {
          active: true,
          timeframes: [ ['08:00', '17:00'] ]
        },
        sat: {
          active: true,
          timeframes: [ ['08:00', '17:00'] ]
        },
        sun: {
          active: true,
          timeframes: [ ['08:00', '17:00'] ]
        },
      },
      public_holidays: {
        '2015-09-22' => {
          'active' => true,
          'summary' => 'test 1',
        },
        '2015-09-23' => {
          'active' => false,
          'summary' => 'test 2',
        },
        '2015-09-24' => {
          'removed' => false,
          'summary' => 'test 3',
        },
      },
      default: true,
      ical_url: nil,
      updated_by_id: 1,
      created_by_id: 1,
    )
    sla = Sla.create_or_update(
      name: 'test sla 4',
      condition: {},
      calendar_id: calendar.id,
      first_response_time: 120,
      update_time: 180,
      solution_time: 240,
      updated_by_id: 1,
      created_by_id: 1,
    )
    #puts Delayed::Job.all.inspect
    Delayed::Worker.new.work_off
    ticket = Ticket.find(ticket.id)
    assert_equal( ticket.escalation_time.gmtime.to_s, '2013-10-21 11:30:00 UTC', 'ticket.escalation_time verify 1' )
    assert_equal( ticket.first_response_escal_date.gmtime.to_s, '2013-10-21 11:30:00 UTC', 'ticket.first_response_escal_date verify 1' )
    assert_equal( ticket.update_time_escal_date.gmtime.to_s, '2013-10-21 12:30:00 UTC', 'ticket.update_time_escal_date verify 1' )
    assert_equal( ticket.close_time_escal_date.gmtime.to_s, '2013-10-21 13:30:00 UTC', 'ticket.close_time_escal_date verify 1' )

    delete = ticket.destroy
    assert( delete, 'ticket destroy' )

    delete = sla.destroy
    assert( delete, 'sla destroy' )

    ticket = Ticket.create(
      title: 'some title äöüß',
      group: Group.lookup( name: 'Users'),
      customer_id: 2,
      state: Ticket::State.lookup( name: 'new' ),
      priority: Ticket::Priority.lookup( name: '2 normal' ),
      created_at: '2013-10-21 05:30:00 UTC',
      updated_at: '2013-10-21 05:30:00 UTC',
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert( ticket, 'ticket created' )
    assert_equal( ticket.escalation_time, nil, 'ticket.escalation_time verify' )

    # set sla's for timezone "Europe/Berlin" summertime (+2), so UTC times are 6:00-15:00
    sla = Sla.create_or_update(
      name: 'test sla 5',
      condition: {},
      calendar_id: calendar.id,
      first_response_time: 120,
      update_time: 180,
      solution_time: 240,
      updated_by_id: 1,
      created_by_id: 1,
    )
    #puts Delayed::Job.all.inspect
    Delayed::Worker.new.work_off
    ticket = Ticket.find(ticket.id)
    assert_equal( ticket.escalation_time.gmtime.to_s, '2013-10-21 08:00:00 UTC', 'ticket.escalation_time verify 1' )
    assert_equal( ticket.first_response_escal_date.gmtime.to_s, '2013-10-21 08:00:00 UTC', 'ticket.first_response_escal_date verify 1' )
    assert_equal( ticket.update_time_escal_date.gmtime.to_s, '2013-10-21 09:00:00 UTC', 'ticket.update_time_escal_date verify 1' )
    assert_equal( ticket.close_time_escal_date.gmtime.to_s, '2013-10-21 10:00:00 UTC', 'ticket.close_time_escal_date verify 1' )

    ticket = Ticket.create(
      title: 'some title holiday test',
      group: Group.lookup( name: 'Users'),
      customer_id: 2,
      state: Ticket::State.lookup( name: 'new' ),
      priority: Ticket::Priority.lookup( name: '2 normal' ),
      created_at: '2015-09-21 14:30:00 UTC',
      updated_at: '2015-09-21 14:30:00 UTC',
      updated_by_id: 1,
      created_by_id: 1,
    )
    ticket = Ticket.find(ticket.id)
    assert_equal( ticket.escalation_time.gmtime.to_s, '2015-09-23 07:30:00 UTC', 'ticket.escalation_time verify 1' )
    assert_equal( ticket.first_response_escal_date.gmtime.to_s, '2015-09-23 07:30:00 UTC', 'ticket.first_response_escal_date verify 1' )
    assert_equal( ticket.update_time_escal_date.gmtime.to_s, '2015-09-23 08:30:00 UTC', 'ticket.update_time_escal_date verify 1' )
    assert_equal( ticket.close_time_escal_date.gmtime.to_s, '2015-09-23 09:30:00 UTC', 'ticket.close_time_escal_date verify 1' )

    delete = sla.destroy
    assert( delete, 'sla destroy' )

    delete = ticket.destroy
    assert( delete, 'ticket destroy' )

  end

  test 'ticket escalation suspend' do
    ticket = Ticket.create(
      title: 'some title äöüß3',
      group: Group.lookup( name: 'Users'),
      customer_id: 2,
      state: Ticket::State.lookup( name: 'new' ),
      priority: Ticket::Priority.lookup( name: '2 normal' ),
      created_at: '2013-06-04 09:00:00 UTC',
      updated_at: '2013-06-04 09:00:00 UTC',
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert( ticket, 'ticket created' )

    # set ticket at 10:00 to pending
    History.add(
      history_type: 'updated',
      history_object: 'Ticket',
      history_attribute: 'state',
      o_id: ticket.id,
      id_to: 3,
      id_from: 2,
      value_from: 'open',
      value_to: 'pending reminder',
      created_by_id: 1,
      created_at: '2013-06-04 10:00:00 UTC',
      updated_at: '2013-06-04 10:00:00 UTC',
    )

    # set ticket at 10:30 to open
    History.add(
      history_type: 'updated',
      history_object: 'Ticket',
      history_attribute: 'state',
      o_id: ticket.id,
      id_to: 2,
      id_from: 3,
      value_from: 'pending reminder',
      value_to: 'open',
      created_by_id: 1,
      created_at: '2013-06-04 10:30:00 UTC',
      updated_at: '2013-06-04 10:30:00 UTC'
    )

    # set update time
    ticket.update_attributes(
      last_contact_agent: '2013-06-04 10:15:00 UTC',
    )

    # set first response time
    ticket.update_attributes(
      first_response: '2013-06-04 10:45:00 UTC',
    )

    # set ticket from 11:30 to closed
    History.add(
      history_type: 'updated',
      history_object: 'Ticket',
      history_attribute: 'state',
      o_id: ticket.id,
      id_to: 3,
      id_from: 2,
      value_from: 'open',
      value_to: 'closed',
      created_by_id: 1,
      created_at: '2013-06-04 12:00:00 UTC',
      updated_at: '2013-06-04 12:00:00 UTC'
    )

    ticket.update_attributes(
      close_time: '2013-06-04 12:00:00 UTC',
    )

    # set sla's for timezone "Europe/Berlin" summertime (+2), so UTC times are 7:00-16:00
    calendar = Calendar.create_or_update(
      name: 'EU 5',
      timezone: 'Europe/Berlin',
      business_hours: {
        mon: {
          active: true,
          timeframes: [ ['09:00', '18:00'] ]
        },
        tue: {
          active: true,
          timeframes: [ ['09:00', '18:00'] ]
        },
        wed: {
          active: true,
          timeframes: [ ['09:00', '18:00'] ]
        },
        thu: {
          active: true,
          timeframes: [ ['09:00', '18:00'] ]
        },
        fri: {
          active: true,
          timeframes: [ ['09:00', '18:00'] ]
        },
        sat: {
          active: true,
          timeframes: [ ['09:00', '18:00'] ]
        },
        sun: {
          active: true,
          timeframes: [ ['09:00', '18:00'] ]
        },
      },
      default: true,
      ical_url: nil,
      updated_by_id: 1,
      created_by_id: 1,
    )
    sla = Sla.create_or_update(
      name: 'test sla 5',
      condition: {},
      calendar_id: calendar.id,
      first_response_time: 120,
      update_time: 180,
      solution_time: 250,
      updated_by_id: 1,
      created_by_id: 1,
    )
    #puts Delayed::Job.all.inspect
    Delayed::Worker.new.work_off
    ticket = Ticket.find(ticket.id)
    assert_equal( ticket.escalation_time.gmtime.to_s, '2013-06-04 13:30:00 UTC', 'ticket.escalation_time verify 1' )
    assert_equal( ticket.first_response_escal_date.gmtime.to_s, '2013-06-04 11:30:00 UTC', 'ticket.first_response_escal_date verify 1' )
    assert_equal( ticket.first_response_in_min, 75, 'ticket.first_response_in_min verify 3' )
    assert_equal( ticket.first_response_diff_in_min, 45, 'ticket.first_response_diff_in_min verify 3' )
    assert_equal( ticket.update_time_escal_date.gmtime.to_s, '2013-06-04 13:30:00 UTC', 'ticket.update_time_escal_date verify 1' )
    assert_equal( ticket.close_time_escal_date.gmtime.to_s, '2013-06-04 13:40:00 UTC', 'ticket.close_time_escal_date verify 1' )
    assert_equal( ticket.close_time_in_min, 150, 'ticket.close_time_in_min verify 3' )
    assert_equal( ticket.close_time_diff_in_min, 100, 'ticket.close_time_diff_in_min# verify 3' )
    delete = sla.destroy
    assert( delete, 'sla destroy' )

    delete = ticket.destroy
    assert( delete, 'ticket destroy' )

    # test Ticket created in state pending and closed without reopen or state change
    ticket = Ticket.create(
      title: 'some title äöüß3',
      group: Group.lookup( name: 'Users'),
      customer_id: 2,
      state: Ticket::State.lookup( name: 'pending reminder' ),
      priority: Ticket::Priority.lookup( name: '2 normal' ),
      created_at: '2013-06-04 09:00:00 UTC',
      updated_at: '2013-06-04 09:00:00 UTC',
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert( ticket, 'ticket created' )

    # set ticket from 11:30 to closed
    History.add(
      history_type: 'updated',
      history_object: 'Ticket',
      history_attribute: 'state',
      o_id: ticket.id,
      id_to: 4,
      id_from: 3,
      value_from: 'pending reminder',
      value_to: 'closed',
      created_by_id: 1,
      created_at: '2013-06-04 12:00:00 UTC',
      updated_at: '2013-06-04 12:00:00 UTC',
    )
    ticket.update_attributes(
      close_time: '2013-06-04 12:00:00 UTC',
    )

    calendar = Calendar.create_or_update(
      name: 'EU 5',
      timezone: 'Europe/Berlin',
      business_hours: {
        mon: {
          active: true,
          timeframes: [ ['09:00', '18:00'] ]
        },
        tue: {
          active: true,
          timeframes: [ ['09:00', '18:00'] ]
        },
        wed: {
          active: true,
          timeframes: [ ['09:00', '18:00'] ]
        },
        thu: {
          active: true,
          timeframes: [ ['09:00', '18:00'] ]
        },
        fri: {
          active: true,
          timeframes: [ ['09:00', '18:00'] ]
        },
        sat: {
          active: true,
          timeframes: [ ['09:00', '18:00'] ]
        },
        sun: {
          active: true,
          timeframes: [ ['09:00', '18:00'] ]
        },
      },
      default: true,
      ical_url: nil,
      updated_by_id: 1,
      created_by_id: 1,
    )
    sla = Sla.create_or_update(
      name: 'test sla 5',
      condition: {},
      calendar_id: calendar.id,
      first_response_time: 120,
      update_time: 180,
      solution_time: 240,
      updated_by_id: 1,
      created_by_id: 1,
    )
    #puts Delayed::Job.all.inspect
    Delayed::Worker.new.work_off
    ticket = Ticket.find(ticket.id)
    assert_equal( ticket.escalation_time, nil, 'ticket.escalation_time verify 1' )
    assert_equal( ticket.first_response_escal_date.gmtime.to_s, '2013-06-04 13:00:00 UTC', 'ticket.first_response_escal_date verify 1' )
    assert_equal( ticket.first_response_in_min, nil, 'ticket.first_response_in_min verify 3' )
    assert_equal( ticket.first_response_diff_in_min, nil, 'ticket.first_response_diff_in_min verify 3' )
    assert_equal( ticket.update_time_escal_date.gmtime.to_s, '2013-06-04 15:00:00 UTC', 'ticket.update_time_escal_date verify 1' )
    assert_equal( ticket.close_time_escal_date.gmtime.to_s, '2013-06-04 16:00:00 UTC', 'ticket.close_time_escal_date verify 1' )
    assert_equal( ticket.close_time_in_min, 0, 'ticket.close_time_in_min verify 3' )
    assert_equal( ticket.close_time_diff_in_min, 240, 'ticket.close_time_diff_in_min# verify 3' )

    delete = sla.destroy
    assert( delete, 'sla destroy' )

    delete = ticket.destroy
    assert( delete, 'ticket destroy' )

    # test Ticket created in state pending, changed state to openen, back to pending and closed
    ticket = Ticket.create(
      title: 'some title äöüß3',
      group: Group.lookup( name: 'Users'),
      customer_id: 2,
      state: Ticket::State.lookup( name: 'pending reminder' ),
      priority: Ticket::Priority.lookup( name: '2 normal' ),
      created_at: '2013-06-04 09:00:00 UTC',
      updated_at: '2013-06-04 09:00:00 UTC',
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert( ticket, 'ticket created' )

    # state change to open 10:30
    History.add(
      history_type: 'updated',
      history_object: 'Ticket',
      history_attribute: 'state',
      o_id: ticket.id,
      id_to: 2,
      id_from: 3,
      value_from: 'pending reminder',
      value_to: 'open',
      created_by_id: 1,
      created_at: '2013-06-04 10:30:00 UTC',
      updated_at: '2013-06-04 10:30:00 UTC',
    )

    # state change to pending 11:00
    History.add(
      history_type: 'updated',
      history_object: 'Ticket',
      history_attribute: 'state',
      o_id: ticket.id,
      id_to: 3,
      id_from: 2,
      value_from: 'open',
      value_to: 'pending reminder',
      created_by_id: 1,
      created_at: '2013-06-04 11:00:00 UTC',
      updated_at: '2013-06-04 11:00:00 UTC',
    )

    # set ticket from 12:00 to closed
    History.add(
      history_type: 'updated',
      history_object: 'Ticket',
      history_attribute: 'state',
      o_id: ticket.id,
      id_to: 4,
      id_from: 3,
      value_from: 'pending reminder',
      value_to: 'closed',
      created_by_id: 1,
      created_at: '2013-06-04 12:00:00 UTC',
      updated_at: '2013-06-04 12:00:00 UTC',
    )
    ticket.update_attributes(
      close_time: '2013-06-04 12:00:00 UTC',
    )

    calendar = Calendar.create_or_update(
      name: 'EU 5',
      timezone: 'Europe/Berlin',
      business_hours: {
        mon: {
          active: true,
          timeframes: [ ['09:00', '18:00'] ]
        },
        tue: {
          active: true,
          timeframes: [ ['09:00', '18:00'] ]
        },
        wed: {
          active: true,
          timeframes: [ ['09:00', '18:00'] ]
        },
        thu: {
          active: true,
          timeframes: [ ['09:00', '18:00'] ]
        },
        fri: {
          active: true,
          timeframes: [ ['09:00', '18:00'] ]
        },
        sat: {
          active: true,
          timeframes: [ ['09:00', '18:00'] ]
        },
        sun: {
          active: true,
          timeframes: [ ['09:00', '18:00'] ]
        },
      },
      default: true,
      ical_url: nil,
      updated_by_id: 1,
      created_by_id: 1,
    )
    sla = Sla.create_or_update(
      name: 'test sla 5',
      condition: {},
      calendar_id: calendar.id,
      first_response_time: 120,
      update_time: 180,
      solution_time: 240,
      updated_by_id: 1,
      created_by_id: 1,
    )
    #puts Delayed::Job.all.inspect
    Delayed::Worker.new.work_off
    ticket = Ticket.find(ticket.id)
    assert_equal( ticket.escalation_time, nil, 'ticket.escalation_time verify 1' )
    assert_equal( ticket.first_response_escal_date.gmtime.to_s, '2013-06-04 12:30:00 UTC', 'ticket.first_response_escal_date verify 1' )
    assert_equal( ticket.first_response_in_min, nil, 'ticket.first_response_in_min verify 3' )
    assert_equal( ticket.first_response_diff_in_min, nil, 'ticket.first_response_diff_in_min verify 3' )
    assert_equal( ticket.update_time_escal_date.gmtime.to_s, '2013-06-04 14:30:00 UTC', 'ticket.update_time_escal_date verify 1' )
    assert_equal( ticket.close_time_escal_date.gmtime.to_s, '2013-06-04 15:30:00 UTC', 'ticket.close_time_escal_date verify 1' )
    assert_equal( ticket.close_time_in_min, 30, 'ticket.close_time_in_min verify 3' )
    assert_equal( ticket.close_time_diff_in_min, 210, 'ticket.close_time_diff_in_min# verify 3' )

    delete = sla.destroy
    assert( delete, 'sla destroy' )

    delete = ticket.destroy
    assert( delete, 'ticket destroy' )

    ### Test Ticket created in state pending, changed state to openen, back to pending and back to open then
    ### close ticket
    ticket = Ticket.create(
      title: 'some title äöüß3',
      group: Group.lookup( name: 'Users'),
      customer_id: 2,
      state: Ticket::State.lookup( name: 'pending reminder' ),
      priority: Ticket::Priority.lookup( name: '2 normal' ),
      created_at: '2013-06-04 09:00:00 UTC',
      updated_at: '2013-06-04 09:00:00 UTC',
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert( ticket, 'ticket created' )

    # state change to open from pending
    History.add(
      history_type: 'updated',
      history_object: 'Ticket',
      history_attribute: 'state',
      o_id: ticket.id,
      id_to: 2,
      id_from: 3,
      value_from: 'pending reminder',
      value_to: 'open',
      created_by_id: 1,
      created_at: '2013-06-04 10:30:00 UTC',
      updated_at: '2013-06-04 10:30:00 UTC',
    )

    # state change to pending from open 11:00
    History.add(
      history_type: 'updated',
      history_object: 'Ticket',
      history_attribute: 'state',
      o_id: ticket.id,
      id_to: 3,
      id_from: 2,
      value_from: 'open',
      value_to: 'pending reminder',
      created_by_id: 1,
      created_at: '2013-06-04 11:00:00 UTC',
      updated_at: '2013-06-04 11:00:00 UTC',
    )

    # state change to open 11:30
    History.add(
      history_type: 'updated',
      history_object: 'Ticket',
      history_attribute: 'state',
      o_id: ticket.id,
      id_to: 2,
      id_from: 3,
      value_from: 'pending reminder',
      value_to: 'open',
      created_by_id: 1,
      created_at: '2013-06-04 11:30:00 UTC',
      updated_at: '2013-06-04 11:30:00 UTC',
    )

    # set ticket from open to closed 12:00
    History.add(
      history_type: 'updated',
      history_object: 'Ticket',
      history_attribute: 'state',
      o_id: ticket.id,
      id_to: 4,
      id_from: 3,
      value_from: 'open',
      value_to: 'closed',
      created_by_id: 1,
      created_at: '2013-06-04 12:00:00 UTC',
      updated_at: '2013-06-04 12:00:00 UTC',
    )
    ticket.update_attributes(
      close_time: '2013-06-04 12:00:00 UTC',
    )

    calendar = Calendar.create_or_update(
      name: 'EU 5',
      timezone: 'Europe/Berlin',
      business_hours: {
        mon: {
          active: true,
          timeframes: [ ['09:00', '18:00'] ]
        },
        tue: {
          active: true,
          timeframes: [ ['09:00', '18:00'] ]
        },
        wed: {
          active: true,
          timeframes: [ ['09:00', '18:00'] ]
        },
        thu: {
          active: true,
          timeframes: [ ['09:00', '18:00'] ]
        },
        fri: {
          active: true,
          timeframes: [ ['09:00', '18:00'] ]
        },
        sat: {
          active: true,
          timeframes: [ ['09:00', '18:00'] ]
        },
        sun: {
          active: true,
          timeframes: [ ['09:00', '18:00'] ]
        },
      },
      default: true,
      ical_url: nil,
      updated_by_id: 1,
      created_by_id: 1,
    )
    sla = Sla.create_or_update(
      name: 'test sla 5',
      condition: {},
      calendar_id: calendar.id,
      first_response_time: 120,
      update_time: 180,
      solution_time: 240,
      updated_by_id: 1,
      created_by_id: 1,
    )
    #puts Delayed::Job.all.inspect
    Delayed::Worker.new.work_off
    ticket = Ticket.find(ticket.id)
    assert_equal( ticket.escalation_time, nil, 'ticket.escalation_time verify 1' )
    assert_equal( ticket.first_response_escal_date.gmtime.to_s, '2013-06-04 12:30:00 UTC', 'ticket.first_response_escal_date verify 1' )
    assert_equal( ticket.first_response_in_min, nil, 'ticket.first_response_in_min verify 3' )
    assert_equal( ticket.first_response_diff_in_min, nil, 'ticket.first_response_diff_in_min verify 3' )
    assert_equal( ticket.update_time_escal_date.gmtime.to_s, '2013-06-04 14:00:00 UTC', 'ticket.update_time_escal_date verify 1' )
    assert_equal( ticket.close_time_escal_date.gmtime.to_s, '2013-06-04 15:00:00 UTC', 'ticket.close_time_escal_date verify 1' )
    assert_equal( ticket.close_time_in_min, 60, 'ticket.close_time_in_min verify 3' )
    assert_equal( ticket.close_time_diff_in_min, 180, 'ticket.close_time_diff_in_min# verify 3' )

    delete = sla.destroy
    assert( delete, 'sla destroy' )

    delete = ticket.destroy
    assert( delete, 'ticket destroy' )

  end

end
