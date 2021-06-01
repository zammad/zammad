# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'browser_test_helper'

class AgentTicketUpdate3Test < TestCase
  def test_work_with_two_browser_on_same_ticket

    # work on one ticket with two browsers
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

    # create ticket
    ticket1 = ticket_create(
      browser: browser1,
      data:    {
        group:    'Users',
        customer: 'nicole',
        title:    'some level 2 <b>subject</b> 123äöü',
        body:     'some level 2 <b>body</b> 123äöü',
      }
    )

    # open ticket in second browser
    ticket_open_by_search(
      browser: browser2,
      number:  ticket1[:number],
    )
    watch_for(
      browser: browser2,
      css:     '.active div.ticket-article',
      value:   'some level 2 <b>body</b> 123äöü',
    )

    # set body in edit area in second
    ticket_update(
      browser:       browser2,
      data:          {
        body: 'some level 2 <b>body</b> in instance 2',
      },
      do_not_submit: true,
    )

    # set body in edit area in first
    ticket_update(
      browser:       browser1,
      data:          {
        body: 'some level 2 <b>body</b> in instance 1',
      },
      do_not_submit: true,
    )

    # change title in second browser
    ticket_update(
      browser:       browser2,
      data:          {
        title: 'TTTsome level 2 <b>subject</b> 123äöü',
      },
      do_not_submit: true,
    )
    sleep 2

    # verify title in second and first browser
    verify_title(
      browser: browser2,
      value:   'TTTsome level 2 <b>subject<\/b> 123äöü',
    )
    ticket_verify(
      browser: browser2,
      data:    {
        title: 'TTTsome level 2 <b>subject<\/b> 123äöü',
      },
    )
    verify_task(
      browser: browser2,
      data:    {
        title:    'TTTsome level 2 <b>subject<\/b> 123äöü',
        modified: false,
      }
    )

    sleep 4
    verify_title(
      browser: browser1,
      value:   'TTTsome level 2 <b>subject<\/b> 123äöü',
    )
    ticket_verify(
      browser: browser1,
      data:    {
        title: 'TTTsome level 2 <b>subject<\/b> 123äöü',
      },
    )
    verify_task(
      browser: browser1,
      data:    {
        title:    'TTTsome level 2 <b>subject<\/b> 123äöü',
        modified: true,
      }
    )

    # verify text in input body, if still exists
    ticket_verify(
      browser: browser1,
      data:    {
        body: 'some level 2 <b>body</b> in instance 1',
      },
    )
    ticket_verify(
      browser: browser2,
      data:    {
        body: 'some level 2 <b>body</b> in instance 2',
      },
    )

    # set body in edit area in second
    ticket_update(
      browser: browser1,
      data:    {
        body: 'some update 4711',
      },
    )
    watch_for(
      browser: browser1,
      css:     '.active div.ticket-article',
      value:   'some update 4711',
    )
    verify_task(
      browser: browser1,
      data:    {
        title:    'TTTsome level 2 <b>subject<\/b> 123äöü',
        modified: false,
      }
    )

    # verify if text in input body is now empty
    ticket_verify(
      browser: browser1,
      data:    {
        body: '',
      },
    )

    # check if body is still in second browser
    ticket_verify(
      browser: browser2,
      data:    {
        body: 'some level 2 <b>body</b> in instance 2',
      },
    )

    # verify task
    verify_task(
      browser: browser2,
      data:    {
        title:    'TTTsome level 2 <b>subject<\/b> 123äöü',
        modified: true,
      }
    )

    # reload instances, verify again
    reload(
      browser: browser1,
    )
    reload(
      browser: browser2,
    )

    # wait till application become ready
    sleep 8
    verify_title(
      browser: browser2,
      value:   'TTTsome level 2 <b>subject<\/b> 123äöü',
    )
    ticket_verify(
      browser: browser2,
      data:    {
        title: 'TTTsome level 2 <b>subject<\/b> 123äöü',
      },
    )
    verify_task(
      browser: browser2,
      data:    {
        title:    'TTTsome level 2 <b>subject<\/b> 123äöü',
        modified: false, # modify was muted at reload ticket tab
      }
    )

    verify_title(
      browser: browser1,
      value:   'TTTsome level 2 <b>subject<\/b> 123äöü',
    )
    ticket_verify(
      browser: browser1,
      data:    {
        title: 'TTTsome level 2 <b>subject<\/b> 123äöü',
      },
    )
    verify_task(
      browser: browser1,
      data:    {
        title:    'TTTsome level 2 <b>subject<\/b> 123äöü',
        modified: false,
      }
    )

    # verify if update is on ticket in each browser
    watch_for(
      browser: browser1,
      css:     '.active div.ticket-article',
      value:   'some update 4711',
    )
    watch_for(
      browser: browser2,
      css:     '.active div.ticket-article',
      value:   'some update 4711',
    )

    # verify if text in input body is now empty
    ticket_verify(
      browser: browser1,
      data:    {
        body: '',
      },
    )

    # check if body is still in second browser
    ticket_verify(
      browser: browser2,
      data:    {
        body: 'some level 2 <b>body</b> in instance 2',
      },
    )

    # modify ticket again and erase modified via mouse click on .active.content
    ticket_update(
      browser: browser1,
      data:    {
        body: 'some update 4711/2',
      },
    )
    sleep 4
    verify_task(
      browser: browser2,
      data:    {
        title:    'TTTsome level 2 <b>subject<\/b> 123äöü',
        modified: true,
      }
    )
    click(
      browser: browser2,
      css:     '.active.content',
    )
    sleep 4
    verify_task(
      browser: browser2,
      data:    {
        title:    'TTTsome level 2 <b>subject<\/b> 123äöü',
        modified: false,
      }
    )
  end
end
