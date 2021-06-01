# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'browser_test_helper'

class KeyboardShortcutsTest < TestCase
  def test_navigation
    @browser = browser_instance
    login(
      username: 'master@example.com',
      password: 'test',
      url:      browser_url,
    )
    tasks_close_all()
    sleep 2

    # show shortkeys
    shortcut(key: 'h')

    # ff issue, sometimes shortcut is not fired in browser test env
    if ENV['BROWSER'] && ENV['BROWSER'] =~ %r{firefox}i
      exists = false
      (1..4).each do |_count|
        sleep 1
        next if !@browser.find_elements(css: '.modal')[0]

        exists = true
      end
      if !exists
        reload
        sleep 4
        shortcut(key: 'h')
        (1..4).each do |_count|
          sleep 1
          next if !@browser.find_elements(css: '.modal')[0]

          exists = true
        end
      end
      if !exists
        shortcut(key: 'h')
      end
    end

    modal_ready()
    # hide shortkeys
    shortcut(key: 'h')
    modal_disappear()

    # show shortkeys
    shortcut(key: 'h')
    modal_ready()

    # show notifications
    shortcut(key: 'a')
    watch_for(
      css:     '.js-notificationsContainer .js-header',
      value:   'Notification',
      timeout: 10,
    )

    shortcut(key: 'a')
    watch_for_disappear(
      css:     '.js-notificationsContainer .js-header',
      value:   'Notification',
      timeout: 2,
    )

    # go to overviews
    shortcut(key: 'o')
    watch_for(
      css:     '.active.content',
      value:   'My assigned Tickets',
      timeout: 2,
    )

    # go to dashboard
    shortcut(key: 'd')
    watch_for(
      css:     '.active.content',
      value:   'My Stats',
      timeout: 2,
    )

    # go to new ticket
    shortcut(key: 'n')
    watch_for(
      css:     '.active.content',
      value:   'New Ticket',
      timeout: 2,
    )

    # close again
    shortcut(key: 'w')

    watch_for_disappear(
      css:     '.active.content',
      value:   'New Ticket',
      timeout: 2,
    )

    ticket1 = ticket_create(
      data: {
        customer: 'nico',
        group:    'Users',
        title:    'Test Ticket for Shortcuts - ABC123',
        body:     'Test Ticket Body for Shortcuts - ABC123',
      },
    )
    sleep 5

    # close again
    shortcut(key: 'w')
    watch_for_disappear(
      css:     '.active.content',
      value:   ticket1[:number],
      timeout: 2,
    )

    # search it
    shortcut(key: 's')
    window_keys(value: ticket1[:number])
    exists(css: '#navigation .search.open')
    sleep 2
    window_keys(value: :arrow_down)
    window_keys(value: :arrow_down)
    window_keys(value: :enter)
    watch_for(
      css:     '.active.content',
      value:   ticket1[:number],
      timeout: 2,
    )
    exists_not(css: '#navigation .search.open')

    # open ticket
    shortcut(key: 's')
    window_keys(value: ticket1[:number])
    sleep 2
    window_keys(value: :arrow_down)
    window_keys(value: :arrow_down)
    window_keys(value: :enter)

    # open new ticket
    shortcut(key: 'n')
    watch_for(
      css:     '.active.content',
      value:   'New Ticket',
      timeout: 2,
    )

    tab_count = @browser.find_elements(css: '#navigation .tasks .task').count
    assert_equal(2, tab_count)

    # tab is tab
    shortcut(key: :tab)
    watch_for(
      css:     '.active.content',
      value:   ticket1[:number],
      timeout: 2,
    )
    shortcut(key: 'm')
    shortcut(key: 'j')
    window_keys(value: 'some note')
    sleep 1
    shortcut(key: :enter)
    watch_for(
      css:     '.active.content .ticket-article',
      value:   'some note',
      timeout: 6,
    )
    exists(css: '.active.content .ticket-article .internal-border')

    shortcut(key: 'g')
    window_keys(value: 'some reply')
    sleep 1
    shortcut(key: :enter)
    watch_for(
      css:     '.active.content .ticket-article',
      value:   'some reply',
      timeout: 6,
    )

    shortcut(key: 'c')
    watch_for(
      css:     '.active.content .sidebar-content .edit',
      value:   'closed',
      timeout: 6,
    )

    # open online notification
    @browser_agent = browser_instance
    login(
      browser:  @browser_agent,
      username: 'agent1@example.com',
      password: 'test',
      url:      browser_url,
    )
    ticket2 = ticket_create(
      browser: @browser_agent,
      data:    {
        customer: 'nico',
        group:    'Users',
        title:    'Test Ticket for Shortcuts II - ABC123',
        body:     'Test Ticket Body for Shortcuts II - ABC123',
      },
    )
    sleep 5
    shortcut(key: 'a')
    # flanky
    watch_for(
      css:     '.js-notificationsContainer',
      value:   'Test Ticket for Shortcuts II',
      timeout: 10,
    )
    window_keys(value: :arrow_down)
    window_keys(value: :enter)
    watch_for(
      css:     '.active.content',
      value:   ticket2[:number],
      timeout: 3,
    )

    shortcut(key: 'e')
    watch_for(
      css:     'body',
      value:   'login',
      timeout: 4,
    )

  end
end
