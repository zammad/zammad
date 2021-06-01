# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'browser_test_helper'

class UserSwitchCache < TestCase
  def test_re_login

    # login as agent and create one ticket
    @browser = browser_instance
    login(
      username: 'agent1@example.com',
      password: 'test',
      url:      browser_url,
    )
    tasks_close_all()
    ticket_create(
      data: {
        customer: 'nico',
        group:    'Users',
        title:    'some subject 123äöü - reply test',
        body:     'some body 123äöü - reply test',
      },
    )

    logout()

    # login as customer and verify ticket create screen
    login(
      username: 'nicole.braun@zammad.org',
      password: 'test',
      url:      browser_url,
    )
    click(css: 'a[href="#new"]', only_if_exists: true)
    click(css: 'a[href="#customer_ticket_new"]')
    sleep 4

    match(
      css:              '#content',
      value:            'Priority',
      should_not_match: true,
    )

    match(
      css:              '#content',
      value:            'Owner',
      should_not_match: true,
    )

    match(
      css:   '#content',
      value: 'State',
    )

    logout()

    # login again as customer and verify ticket create screen
    login(
      username: 'nicole.braun@zammad.org',
      password: 'test',
      url:      browser_url,
    )
    click(css: 'a[href="#new"]', only_if_exists: true)
    click(css: 'a[href="#customer_ticket_new"]')
    sleep 4

    match(
      css:              '#content',
      value:            'Priority',
      should_not_match: true,
    )

    match(
      css:              '#content',
      value:            'Owner',
      should_not_match: true,
    )

    match(
      css:   '#content',
      value: 'State',
    )

  end
end
