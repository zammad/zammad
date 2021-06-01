# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'browser_test_helper'

class AgentTicketUpdateAndReloadTest < TestCase
  def test_agent_ticket_create_with_reload

    @browser = browser_instance
    login(
      username: 'agent1@example.com',
      password: 'test',
      url:      browser_url,
    )
    tasks_close_all()

    # create ticket
    ticket_create(
      data:          {
        customer: 'nicole',
        group:    'Users',
        title:    'some subject 4 - 123äöü',
        body:     'some body 4 - 123äöü',
      },
      do_not_submit: true,
    )
    sleep 6

    # check if customer is shown in sidebar
    click(css: '.active .tabsSidebar-tab[data-tab="customer"]')
    match(
      css:   '.active .sidebar[data-tab="customer"]',
      value: 'nicole',
    )

    # check task title
    verify_task(
      data: {
        title: 'some subject 4 - 123äöü',
      }
    )

    # check page title
    verify_title(
      value: 'some subject 4 - 123äöü',
    )

    # reload instances, verify autosave
    reload()

    # check if customer is still shown in sidebar
    click(css: '.active .tabsSidebar-tab[data-tab="customer"]')
    watch_for(
      css:   '.active .sidebar[data-tab="customer"]',
      value: 'nicole',
    )
    sleep 2

    # finally create ticket
    click(css: '.content.active .js-submit')
    sleep 5

    location_check(
      url: '#ticket/zoom/',
    )

    # check ticket
    match(
      css:   '.active div.ticket-article',
      value: 'some body 4 - 123äöü',
    )

    ticket_id = nil
    if @browser.current_url =~ %r{ticket/zoom/(.+?)$}i
      ticket_id = $1
    end

    # check task title
    verify_task(
      data: {
        title: 'some subject 4 - 123äöü',
      }
    )

    # check page title
    verify_title(
      value: 'some subject 4 - 123äöü',
    )

    # check if task is not marked as modified
    exists(
      css: ".tasks a[href=\"#ticket/zoom/#{ticket_id}\"]",
    )
    exists_not(
      css: ".tasks a[href=\"#ticket/zoom/#{ticket_id}\"].is-modified",
    )

    # reload
    reload()
    sleep 4

    # check task title
    verify_task(
      data: {
        title: 'some subject 4 - 123äöü',
      }
    )

    # check page title
    verify_title(
      value: 'some subject 4 - 123äöü',
    )

    # go to dashboard
    location(
      url: browser_url
    )
    sleep 5

    # check page title
    verify_title(
      value: 'Dashboard',
    )

    # reload
    reload()
    sleep 5

    # check page title
    verify_title(
      value: 'Dashboard',
    )

    # cleanup
    tasks_close_all()
  end
end
