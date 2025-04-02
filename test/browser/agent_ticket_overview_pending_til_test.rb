# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'browser_test_helper'

class AgentTicketOverviewPendingTil < TestCase

  # regression for issue #2367 - cannot sort by Pending Til
  def test_sorting_by_pending_til
    name = "overview_pending_til_#{SecureRandom.uuid}"

    @browser = browser_instance
    login(
      username: 'admin@example.com',
      password: 'test',
      url:      browser_url,
    )
    tasks_close_all

    # create 4 tickets, 2 with pending til data and 2 without
    tickets = []
    4.times do |i|
      ticket = ticket_create(
        data: {
          customer:     'nico',
          group:        'Users',
          title:        "pending til ticket #{i}",
          body:         'test ticket',
          state:        i.odd? ? 'pending close' : 'open',
          pending_date: '11/24/2028',
          pending_time: '08:00',
        }
      )
      tickets.push ticket
    end

    # create and open new overview that has the Pending Til column
    overview_create(
      data: {
        name:       name,
        roles:      %w[Admin Agent],
        selector:   {
          'State' => ['new', 'open', 'closed', 'merged', 'pending close', 'pending reminder'],
        },
        attributes: {
          'pending_time' => true,
        },
      }
    )
    overview_open(
      name: name,
    )

    # sort by Pending Til
    click(
      css: '.content.active table.table th.js-tableHead[data-column-key="pending_time"]',
    )

    # check if the first and second rows both correctly contain 'pending close'
    match(
      css:   '.content.active table .js-tableBody tr:nth-child(1)',
      value: 'pending close',
    )
    match(
      css:   '.content.active table .js-tableBody tr:nth-child(2)',
      value: 'pending close',
    )
  end
end
