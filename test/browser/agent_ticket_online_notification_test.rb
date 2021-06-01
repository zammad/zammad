# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'browser_test_helper'

class AgentTicketOnlineNotificationTest < TestCase

  def test_online_notifications

    @browser = browser_instance
    login(
      username: 'master@example.com',
      password: 'test',
      url:      browser_url,
    )
    tasks_close_all()

    # create new ticket
    ticket_create(
      data: {
        customer: 'nico',
        group:    'Users',
        title:    'online notification #1',
        body:     'online notification #1',
      },
    )

    browser2 = browser_instance
    login(
      browser:  browser2,
      username: 'agent1@example.com',
      password: 'test',
      url:      browser_url,
    )
    tasks_close_all(browser: browser2)

    click(
      browser: browser2,
      css:     '.js-toggleNotifications',
    )
    click(
      browser: browser2,
      css:     '.js-mark',
    )
    sleep 2

    # remove all notificatons
    online_notitifcation_close_all(
      browser: browser2,
    )

    exists_not(
      browser: browser2,
      css:     '.js-noNotifications.hide',
    )
    match(
      browser: browser2,
      css:     '.js-noNotifications',
      value:   'No unread Notifications',
    )
    exists(
      browser: browser2,
      css:     '.js-mark.hide',
    )
    match_not(
      browser:  browser2,
      css:      '.js-notificationsCounter',
      value:    '\d',
      no_quote: true,
    )

    ticket_create(
      data: {
        customer: 'nico',
        group:    'Users',
        title:    'online notification #2',
        body:     'online notification #2',
      },
    )

    watch_for(
      browser: browser2,
      css:     '.js-notificationsContainer .js-item',
      value:   'online notification #2',
      timeout: 10,
    )
    match(
      browser: browser2,
      css:     '.js-notificationsCounter',
      value:   '1',
    )

    exists_not(
      browser: browser2,
      css:     '.js-mark.hide',
    )

    ticket_create(
      data: {
        customer: 'nico',
        group:    'Users',
        title:    'online notification #3',
        body:     'online notification #3',
      },
    )

    watch_for(
      browser: browser2,
      css:     '.js-notificationsContainer .js-item',
      value:   'online notification #3',
      timeout: 6,
    )

    # flanky
    watch_for(
      browser: browser2,
      css:     '.js-notificationsCounter',
      value:   '2',
    )

    items = browser2.find_elements(css: '.js-notificationsContainer .js-item')
    count = items.count
    assert_equal(2, count)

    items[1].click

    click(
      browser: browser2,
      css:     '.js-toggleNotifications',
    )

    watch_for(
      browser: browser2,
      css:     '.js-notificationsCounter',
      value:   '1',
    )

    items = browser2.find_elements(css: '.js-notificationsContainer .js-item')
    assert_equal(2, items.count)

    items = browser2.find_elements(css: '.js-notificationsContainer .js-item.is-inactive')
    assert_equal(1, items.count)

    ticket_create(
      data: {
        customer: 'nico',
        group:    'Users',
        title:    'online notification #4',
        body:     'online notification #4',
      },
    )

    watch_for(
      browser: browser2,
      css:     '.js-notificationsCounter',
      value:   '2',
    )

    items = browser2.find_elements(css: '.js-notificationsContainer .js-item')
    assert_equal(3, items.count)

    items = browser2.find_elements(css: '.js-notificationsContainer .js-item.is-inactive')
    assert_equal(1, items.count)

    click(
      browser: browser2,
      css:     '.js-mark',
    )
    sleep 3

    items = browser2.find_elements(css: '.js-notificationsContainer .js-item')
    assert_equal(3, items.count)

    # flanky
    items = browser2.find_elements(css: '.js-notificationsContainer .js-item.is-inactive')
    assert_equal(3, items.count)

    match_not(
      browser:  browser2,
      css:      '.js-notificationsCounter',
      value:    '\d',
      no_quote: true,
    )

    ticket_create(
      data: {
        customer: 'nico',
        group:    'Users',
        title:    'online notification #5',
        body:     'online notification #5',
      },
    )

    watch_for(
      browser: browser2,
      css:     '.js-notificationsCounter',
      value:   '1',
    )

    items = browser2.find_elements(css: '.js-notificationsContainer .js-item')
    assert_equal(4, items.count)

    items = browser2.find_elements(css: '.js-notificationsContainer .js-item.is-inactive')
    assert_equal(3, items.count)

    # NOTE: title update will generate extra notification - so we will have 5
    ticket_update(
      data: {
        title: 'online notification #5/5',
        state: 'closed',
      },
    )

    watch_for(
      browser: browser2,
      css:     '.js-notificationsContainer .js-item',
      value:   'online notification #5/5',
      timeout: 20,
    )

    watch_for(
      browser: browser2,
      css:     '.js-notificationsContainer .js-item.is-inactive',
      value:   'online notification #5/5',
      timeout: 20,
    )

    match_not(
      browser:  browser2,
      css:      '.js-notificationsCounter',
      value:    '\d',
      no_quote: true,
    )

    items = browser2.find_elements(css: '.js-notificationsContainer .js-item')
    assert_equal(6, items.count)

    items = browser2.find_elements(css: '.js-notificationsContainer .js-item.is-inactive')
    assert_equal(6, items.count)

  end

  def test_online_notifications_render
    @browser = browser_instance
    login(
      username: 'master@example.com',
      password: 'test',
      url:      browser_url,
    )
    tasks_close_all()

    browser2 = browser_instance
    login(
      browser:  browser2,
      username: 'agent1@example.com',
      password: 'test',
      url:      browser_url,
    )
    tasks_close_all(browser: browser2)
    click(
      browser: browser2,
      css:     '.js-toggleNotifications',
    )
    online_notitifcation_close_all(browser: browser2)

    ticket_create(
      data: {
        customer: 'nico',
        group:    'Users',
        title:    'online notification render #1',
        body:     'online notification render #1',
      },
    )
    ticket_create(
      data: {
        customer: 'nico',
        group:    'Users',
        title:    'online notification render #2',
        body:     'online notification render #2',
      },
    )

    watch_for(
      browser: browser2,
      css:     '.js-notificationsCounter',
      value:   '2',
    )

    execute(
      browser: browser2,
      js:      '$(".js-notificationsContainer .js-items .js-item:nth-child(1) .activity-text").text("render test 2")',
    )
    execute(
      browser: browser2,
      js:      '$(".js-notificationsContainer .js-items .js-item:nth-child(2) .activity-text").text("render test 1")',
    )
    match(
      browser: browser2,
      css:     '.js-notificationsContainer .js-items .js-item:nth-child(1) .activity-text',
      value:   'render test 2',
    )
    match(
      browser: browser2,
      css:     '.js-notificationsContainer .js-items .js-item:nth-child(2) .activity-text',
      value:   'render test 1',
    )
    ticket_create(
      data: {
        customer: 'nico',
        group:    'Users',
        title:    'online notification render #3',
        body:     'online notification render #3',
      },
    )
    watch_for(
      browser: browser2,
      css:     '.js-notificationsCounter',
      value:   '3',
    )
    match(
      browser: browser2,
      css:     '.js-notificationsContainer .js-items .js-item:nth-child(1) .activity-text',
      value:   'online notification render #3',
    )
    match(
      browser: browser2,
      css:     '.js-notificationsContainer .js-items .js-item:nth-child(2) .activity-text',
      value:   'render test 2',
    )
    match(
      browser: browser2,
      css:     '.js-notificationsContainer .js-items .js-item:nth-child(3) .activity-text',
      value:   'render test 1',
    )

    ticket_update(
      data: {
        state: 'closed',
      },
    )
    watch_for(
      browser: browser2,
      css:     '.js-notificationsCounter',
      value:   '2',
    )

    match(
      browser: browser2,
      css:     '.js-notificationsContainer .js-items .is-inactive.js-item:nth-child(1) .activity-text',
      value:   'online notification render #3',
    )
    match(
      browser: browser2,
      css:     '.js-notificationsContainer .js-items .is-inactive.js-item:nth-child(2) .activity-text',
      value:   'online notification render #3',
    )
    match(
      browser: browser2,
      css:     '.js-notificationsContainer .js-items .js-item:nth-child(3) .activity-text',
      value:   'render test 2',
    )
    match(
      browser: browser2,
      css:     '.js-notificationsContainer .js-items .js-item:nth-child(4) .activity-text',
      value:   'render test 1',
    )

    execute(
      browser: browser2,
      js:      '$(".js-notificationsContainer .js-items .js-item:nth-child(2) .activity-text").text("render test 3")',
    )

    close_online_notitifcation(
      browser: browser2,
      data:    {
        position: 3,
      },
    )

    match(
      browser: browser2,
      css:     '.js-notificationsContainer .js-items .is-inactive.js-item:nth-child(1) .activity-text',
      value:   'online notification render #3',
    )
    match(
      browser: browser2,
      css:     '.js-notificationsContainer .js-items .js-item:nth-child(2) .activity-text',
      value:   'render test 3',
    )
    match(
      browser: browser2,
      css:     '.js-notificationsContainer .js-items .js-item:nth-child(3) .activity-text',
      value:   'render test 1',
    )

  end

end
