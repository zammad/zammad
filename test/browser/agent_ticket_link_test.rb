# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'browser_test_helper'

class AgentTicketLinkTest < TestCase

  def test_c_link
    @browser = browser_instance
    login(
      username: 'agent1@example.com',
      password: 'test',
      url:      browser_url,
    )
    tasks_close_all()

    ticket1 = ticket_create(
      data: {
        customer: 'nico',
        group:    'Users',
        title:    'some subject - link#1',
        body:     'some body - link#1',
      },
    )

    ticket2 = ticket_create(
      data: {
        customer: 'nico',
        group:    'Users',
        title:    'some subject - link#2',
        body:     'some body - link#2',
      },
    )

    # verify changes in second browser
    browser2 = browser_instance
    login(
      browser:  browser2,
      username: 'master@example.com',
      password: 'test',
      url:      browser_url,
    )
    ticket_open_by_search(
      browser: browser2,
      number:  ticket1[:number],
    )

    click(
      css: '.content.active .js-links .js-add',
    )

    modal_ready()

    set(
      css:   '.content.active .modal-body [name="ticket_number"]',
      value: ticket1[:number],
    )
    select(
      css:   '.content.active .modal-body [name="link_type"]',
      value: 'Normal',
    )
    click(
      css: '.content.active .modal-footer .js-submit',
    )

    watch_for(
      css:   '.content.active .ticketLinks',
      value: ticket1[:title],
    )

    watch_for(
      browser: browser2,
      css:     '.content.active .ticketLinks',
      value:   ticket2[:title],
    )

    reload()

    watch_for(
      css:   '.content.active .ticketLinks',
      value: ticket1[:title],
    )
    click(
      css: '.content.active .ticketLinks .js-delete'
    )
    watch_for_disappear(
      css:   '.content.active .ticketLinks',
      value: ticket1[:title],
    )
    watch_for_disappear(
      browser: browser2,
      css:     '.content.active .ticketLinks',
      value:   ticket2[:title],
    )

    reload()

    watch_for_disappear(
      css:   '.content.active .ticketLinks',
      value: ticket1[:title],
    )
    watch_for_disappear(
      browser: browser2,
      css:     '.content.active .ticketLinks',
      value:   ticket2[:title],
    )

    # cleanup
    ticket_open_by_search(
      browser: browser2,
      number:  ticket1[:number],
    )
    sleep 1

    ticket_update(
      browser: browser2,
      data:    {
        state: 'closed',
      }
    )

    tasks_close_all()

    ticket_open_by_search(
      browser: browser2,
      number:  ticket2[:number],
    )
    sleep 1

    ticket_update(
      browser: browser2,
      data:    {
        state: 'closed',
      }
    )
  end

end
