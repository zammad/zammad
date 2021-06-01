# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'browser_test_helper'

class CustomerTicketCreateTest < TestCase
  def test_customer_ticket_create_and_verify_state_after_update
    @browser = browser_instance
    login(
      username: 'nicole.braun@zammad.org',
      password: 'test',
      url:      browser_url,
    )

    # customer ticket create
    click(css: 'a[href="#new"]', only_if_exists: true)
    click(css: 'a[href="#customer_ticket_new"]')
    sleep 2

    select(
      css:   '.newTicket select[name="group_id"]',
      value: 'Users',
    )

    set(
      css:   '.newTicket input[name="title"]',
      value: 'some subject 123äöü',
    )
    set(
      css:   '.newTicket [data-name="body"]',
      value: 'some body 123äöü',
    )
    exists_not(
      css: '.newTicket input[name="customer_id"]',
    )
    exists_not(
      css: '.newTicket input[name="priority_id"]',
    )

    click(css: '.newTicket button.js-submit')
    sleep 5

    # check if ticket is shown
    location_check(url: '#ticket/zoom/')

    match(
      css:      '.active div.ticket-article',
      value:    'some body 123äöü',
      no_quote: true,
    )

    # verify if the state has changed to open
    match(
      css:   '.content.active .sidebar [name="state_id"]',
      value: 'new',
    )

    # update ticket
    set(
      css:      '.content.active [data-name="body"]',
      value:    'some body 1234 äöüß',
      no_click: true,
    )

    task_type(
      type: 'stayOnTab',
    )

    click(css: '.content.active .js-submit')

    watch_for(
      css:   '.content.active div.ticket-article',
      value: 'some body 1234 äöüß',
    )

    # check if the ticket state is new after update by customer
    match(
      css:   '.content.active .sidebar [name="state_id"]',
      value: 'new',
    )

    # now we want to verify the default followup state
    # for this case we close the ticket first and then
    # write a new article. If the content is written
    # then the state should change initially to open

    # close the ticket
    select(
      css:   '.content.active [name="state_id"]',
      value: 'closed',
    )

    set(
      css:      '.content.active [data-name="body"]',
      value:    'close #1',
      no_click: true,
    )

    click(css: '.content.active .js-submit')
    watch_for(
      css:   '.content.active div.ticket-article',
      value: 'close #1',
    )

    # check if the ticket is closed
    match(
      css:   '.content.active .sidebar [name="state_id"]',
      value: 'closed',
    )

    # type in new content into rte to trigger the default follow-up state
    set(
      css:      '.content.active [data-name="body"]',
      value:    'some body blublub default followup for reopen check',
      no_click: true,
    )

    # verify if the state has changed to open
    watch_for(
      css:   '.content.active .sidebar [name="state_id"]',
      value: 'open',
    )

    # no we verify the reverse way:
    # if the body get changed to empty again then
    # the default follow-up state should get unset and
    # will change to the the default ticket state.

    # remove content from rte
    set(
      css:      '.content.active [data-name="body"]',
      value:    '',
      no_click: true,
    )

    # check if state changed to closed again
    watch_for(
      css:   '.content.active .sidebar [name="state_id"]',
      value: 'closed',
    )

    # type in new content into rte to trigger the default follow-up state
    set(
      css:      '.content.active [data-name="body"]',
      value:    'some body blublub default followup for reopen check',
      no_click: true,
    )

    # verify if the state has changed to open
    watch_for(
      css:   '.content.active .sidebar [name="state_id"]',
      value: 'open',
    )

    # submit and reload to check if the new state is set
    click(css: '.content.active .js-submit')

    watch_for(
      css:   '.content.active div.ticket-article',
      value: 'some body blublub default followup for reopen check',
    )

    # verify if the state has changed to open
    match(
      css:   '.content.active .sidebar [name="state_id"]',
      value: 'open',
    )
  end

  def test_customer_ticket_create_relogin_with_agent_ticket_create
    @browser = browser_instance
    login(
      username: 'nicole.braun@zammad.org',
      password: 'test',
      url:      browser_url,
    )

    # customer ticket create
    click(css: 'a[href="#new"]', only_if_exists: true)
    click(css: 'a[href="#customer_ticket_new"]')
    sleep 2

    select(
      css:   '.newTicket select[name="group_id"]',
      value: 'Users',
    )

    set(
      css:   '.newTicket input[name="title"]',
      value: 'relogin - customer - agent - test 1',
    )
    set(
      css:   '.newTicket [data-name="body"]',
      value: 'relogin - customer - agent - test 1',
    )

    click(css: '.newTicket button.js-submit')
    sleep 5

    # check if ticket is shown
    location_check(url: '#ticket/zoom/')

    match(
      css:      '.active div.ticket-article',
      value:    'relogin - customer - agent - test 1',
      no_quote: true,
    )

    logout()

    # verify if we still can create new tickets as agent
    login(
      username: 'master@example.com',
      password: 'test',
      url:      browser_url,
    )
    tasks_close_all()

    ticket_create(
      data: {
        customer: 'nico',
        group:    'Users',
        title:    'relogin - customer - agent - test 2',
        body:     'relogin - customer - agent - test 2',
        state:    'closed',
      },
    )
  end

  def test_customer_disable_ticket_creation
    @browser = browser_instance

    # disable ticket creation
    login(
      username: 'master@example.com',
      password: 'test',
      url:      browser_url,
    )

    click(css: 'a[href="#manage"]')
    click(css: 'a[href="#channels/web"]')

    @browser.find_element(css: 'select[name=customer_ticket_create]').find_element(css: 'option[value=false]').click
    click(css: '#customer_ticket_create .btn')

    sleep(1)

    logout()

    # check if new ticket button is not visible

    login(
      username: 'nicole.braun@zammad.org',
      password: 'test',
      url:      browser_url,
    )

    assert(exists_not(css: 'a[href="#customer_ticket_new"]'))

    logout()

    # enable ticket creation

    login(
      username: 'master@example.com',
      password: 'test',
      url:      browser_url,
    )

    click(css: 'a[href="#manage"]')
    click(css: 'a[href="#channels/web"]')

    @browser.find_element(css: 'select[name=customer_ticket_create]').find_element(css: 'option[value=true]').click
    click(css: '#customer_ticket_create .btn')

    sleep(1)

    logout()

    # check if new ticket button is visible

    login(
      username: 'nicole.braun@zammad.org',
      password: 'test',
      url:      browser_url,
    )

    assert(exists(css: 'a[href="#customer_ticket_new"]'))
  end
end
