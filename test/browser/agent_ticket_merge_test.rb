# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'browser_test_helper'

class AgentTicketMergeTest < TestCase
  def test_agent_ticket_merge_closed_tab

    # merge ticket with closed tab
    @browser = browser_instance
    login(
      username: 'agent1@example.com',
      password: 'test',
      url:      browser_url,
    )
    tasks_close_all()

    # create new ticket
    ticket1 = ticket_create(
      data: {
        customer: 'nico',
        group:    'Users',
        title:    'some subject 123äöü - with closed tab',
        body:     'some body 123äöü - with closed tab',
      },
    )
    sleep 1

    # update ticket
    ticket_update(
      data: {
        body: 'some body 1234 äöüß - with closed tab',
      },
    )

    tasks_close_all()

    # create second ticket to merge
    ticket_create(
      data: {
        customer: 'nico',
        group:    'Users',
        title:    'test to merge - with closed tab',
        body:     'some body 123äöü 222 - test to merge - with closed tab',
      },
    )

    ticket_update(
      data: {
        body: 'some body 1234 äöüß 333 - with closed tab',
      },
    )

    # check if task is shown
    match(
      css:   '.tasks',
      value: 'test to merge - with closed tab',
    )

    # merge tickets
    click( css: '.active div[data-tab="ticket"] .js-actions .icon-arrow-down' )
    click( css: '.active div[data-tab="ticket"] .js-actions [data-type="ticket-merge"]' )

    modal_ready()
    set(
      css:   '.modal input[name="master_ticket_number"]',
      value: ticket1[:number],
    )

    click( css: '.modal button[type="submit"]' )

    # check if merged to ticket is shown now
    watch_for(
      css:   '.active .ticketZoom-header .ticket-number',
      value: ticket1[:number],
    )
    watch_for(
      css:   '.active .ticket-article',
      value: 'test to merge - with closed tab',
    )

    # check if task is now gone
    match_not(
      css:   '.tasks',
      value: 'test to merge',
    )
    match(
      css:   '.tasks',
      value: 'some subject 123äöü - with closed tab',
    )

    # close task/cleanup
    tasks_close_all()

    # merge ticket with open tabs
    ticket3 = ticket_create(
      data: {
        customer: 'nico',
        group:    'Users',
        title:    'some subject 123äöü - with open tab',
        body:     'some body 123äöü - with open tab',
      },
    )

    ticket_create(
      data: {
        customer: 'nico',
        group:    'Users',
        title:    'test to merge - with open tab',
        body:     'some body 123äöü 222 - test to merge - with open tab',
      },
    )

    # merge tickets
    click( css: '.active div[data-tab="ticket"] .js-actions .icon-arrow-down' )
    click( css: '.active div[data-tab="ticket"] .js-actions [data-type="ticket-merge"]' )

    modal_ready()
    set(
      css:   '.modal input[name="master_ticket_number"]',
      value: ticket3[:number],
    )
    click( css: '.modal button[type="submit"]' )

    # check if merged to ticket is shown now
    watch_for(
      css:   '.active .ticketZoom-header .ticket-number',
      value: ticket3[:number],
    )
    watch_for(
      css:   '.active .ticket-article',
      value: 'test to merge - with open tab',
    )

    # check if task is now gone
    match_not(
      css:   '.tasks',
      value: 'test to merge',
    )
    match(
      css:   '.tasks',
      value: 'some subject 123äöü - with open tab',
    )

  end
end
