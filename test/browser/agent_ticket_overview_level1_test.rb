# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'browser_test_helper'

class AgentTicketOverviewLevel1Test < TestCase
  def test_i
    name1 = "name_low_#{rand(999_999)}"
    name2 = "name_high_#{rand(999_999)}"

    browser1 = browser_instance
    login(
      browser:  browser1,
      username: 'master@example.com',
      password: 'test',
      url:      browser_url,
    )
    tasks_close_all(browser: browser1)

    browser2 = browser_instance
    login(
      browser:  browser2,
      username: 'agent1@example.com',
      password: 'test',
      url:      browser_url,
    )
    tasks_close_all(browser: browser2)

    # create new overview
    overview_create(
      browser: browser1,
      data:    {
        name: name1,
        roles: ['Agent'],
        selector: {
          'Priority' => '1 low',
        },
        'order::direction' => 'down',
      }
    )
    overview_create(
      browser: browser1,
      data:    {
        name: name2,
        roles: ['Agent'],
        selector: {
          'Priority' => '3 high',
        },
        'order::direction' => 'down',
      }
    )

    # create tickets
    ticket1 = ticket_create(
      browser: browser1,
      data:    {
        customer: 'nico',
        priority: '1 low',
        group:    'Users',
        title:    'overview #1',
        body:     'overview #1',
      }
    )

    # keep connection alive
    click(
      browser: browser2,
      css:     '.search-holder',
    )

    ticket2 = ticket_create(
      browser: browser1,
      data:    {
        customer: 'nico',
        priority: '1 low',
        group:    'Users',
        title:    'overview #2',
        body:     'overview #2',
      }
    )

    ticket3 = ticket_create(
      browser: browser1,
      data:    {
        customer: 'nico',
        priority: '1 low',
        group:    'Users',
        title:    'overview #3',
        body:     'overview #3',
      }
    )

    # click on #1 on overview
    ticket_open_by_overview(
      browser: browser2,
      number:  ticket3[:number],
      link:    "#ticket/view/#{name1}",
    )

    # use overview navigation to got to #2 & #3
    match(
      browser: browser2,
      css:     '.active .ticketZoom .ticketZoom-controls .overview-navigator .pagination-counter .pagination-item-current',
      value:   '1',
    )
    match(
      browser: browser2,
      css:     '.active .ticketZoom-header .ticket-number',
      value:   ticket3[:number],
    )

    click(
      browser: browser2,
      css:     '.active .ticketZoom .ticketZoom-controls .overview-navigator .next',
    )
    match(
      browser: browser2,
      css:     '.active .ticketZoom .ticketZoom-controls .overview-navigator .pagination-counter .pagination-item-current',
      value:   '2',
    )
    match(
      browser: browser2,
      css:     '.active .ticketZoom-header .ticket-number',
      value:   ticket2[:number],
    )

    click(
      browser: browser2,
      css:     '.active .ticketZoom .ticketZoom-controls .overview-navigator .next',
    )
    match(
      browser: browser2,
      css:     '.active .ticketZoom .ticketZoom-controls .overview-navigator .pagination-counter .pagination-item-current',
      value:   '3',
    )
    match(
      browser: browser2,
      css:     '.active .ticketZoom-header .ticket-number',
      value:   ticket1[:number],
    )

    # close ticket
    sleep 2 # needed to selenium cache issues
    ticket_update(
      browser: browser2,
      data:    {
        state: 'closed',
      }
    )
    sleep 8

    match(
      browser: browser2,
      css:     '.active .ticketZoom .ticketZoom-controls .overview-navigator .pagination-counter .pagination-item-current',
      value:   '3',
    )
    match(
      browser: browser2,
      css:     '.active .ticketZoom-header .ticket-number',
      value:   ticket1[:number],
    )
    click(
      browser: browser2,
      css:     '.active .ticketZoom .ticketZoom-controls .overview-navigator .previous',
    )

    match(
      browser: browser2,
      css:     '.active .ticketZoom .ticketZoom-controls .overview-navigator .pagination-counter .pagination-item-current',
      value:   '2',
    )
    match(
      browser: browser2,
      css:     '.active .ticketZoom-header .ticket-number',
      value:   ticket2[:number],
    )
    click(
      browser: browser2,
      css:     '.active .ticketZoom .ticketZoom-controls .overview-navigator .next',
    )
    match(
      browser: browser2,
      css:     '.active .ticketZoom-header .ticket-number',
      value:   ticket1[:number],
    )
    sleep 2 # needed to selenium cache issues
    ticket_update(
      browser: browser2,
      data:    {
        state:    'closed',
        priority: '3 high',
      }
    )

    watch_for_disappear(
      browser: browser2,
      css:     '.active .ticketZoom .ticketZoom-controls .overview-navigator .pagination-counter .pagination-item-current',
    )
    match(
      browser: browser2,
      css:     '.active .ticketZoom-header .ticket-number',
      value:   ticket1[:number],
    )

  end
end
