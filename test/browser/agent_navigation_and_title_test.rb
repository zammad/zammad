# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'browser_test_helper'

class AgentNavigationAndTitleTest < TestCase
  def test_highlight_and_title
    @browser = browser_instance
    login(
      username: 'master@example.com',
      password: 'test',
      url:      browser_url,
    )
    tasks_close_all()

    # since we run the basic functionality tests via Capybara now the clues are shown
    # and closed after the login. This unfortunately removes the 'is-active' class from the
    # dashboard link causing the following tests to fail.
    # Because the browser tests are deprecated and there is no easy fix to change the
    # behavior we refresh the page and wait for it to finish loading the app as a workaround.
    # This will cause the 'is-active' class to be set on the menu item again
    reload()
    sleep 4

    # dashboard after login
    verify_title(value: 'dashboard')
    exists(css: '#navigation .js-menu .js-dashboardMenuItem.is-active')
    exists_not(css: '#navigation .tasks .js-item.is-active')

    execute(js: 'App.Event.trigger("ui:rerender")')
    sleep 1
    verify_title(value: 'dashboard')
    exists(css: '#navigation .js-menu .js-dashboardMenuItem.is-active')
    exists_not(css: '#navigation .tasks .js-item.is-active')

    reload()
    sleep 2
    verify_title(value: 'dashboard')
    exists(css: '#navigation .js-menu .js-dashboardMenuItem.is-active')
    exists_not(css: '#navigation .tasks .js-item.is-active')

    # ticket create screen
    ticket_create(
      data:          {
        customer: 'nico',
        group:    'Users',
        title:    'ticket create #1',
        body:     'ticket create #1',
      },
      do_not_submit: true,
    )
    sleep 4
    verify_title(value: 'Call Inbound')
    verify_task(
      data: {
        title: 'Call Inbound: ticket create #1',
      }
    )
    exists_not(css: '#navigation .js-menu .is-active')

    execute(js: 'App.Event.trigger("ui:rerender")')
    sleep 1
    verify_title(value: 'Call Inbound')
    verify_task(
      data: {
        title: 'Call Inbound: ticket create #1',
      }
    )
    exists_not(css: '#navigation .js-menu .is-active')

    reload()
    sleep 2
    verify_title(value: 'Call Inbound')
    verify_task(
      data: {
        title: 'Call Inbound: ticket create #1',
      }
    )
    exists_not(css: '#navigation .js-menu .is-active')

    # ticket zoom screen
    ticket_create(
      data: {
        customer: 'nico',
        group:    'Users',
        state:    'closed',
        title:    'ticket create #2',
        body:     'ticket create #2',
      },
    )
    verify_title(value: 'ticket create #2')
    verify_task(
      data: {
        title: 'ticket create #2',
      }
    )
    exists_not(css: '#navigation .js-menu .is-active')

    execute(js: 'App.Event.trigger("ui:rerender")')
    sleep 1
    verify_title(value: 'ticket create #2')
    verify_task(
      data: {
        title: 'ticket create #2',
      }
    )
    exists_not(css: '#navigation .js-menu .is-active')

    reload()
    sleep 2
    verify_title(value: 'ticket create #2')
    verify_task(
      data: {
        title: 'ticket create #2',
      }
    )
    exists_not(css: '#navigation .js-menu .is-active')

    # dashboard again
    click(css: '#navigation a[href="#dashboard"]')
    verify_title(value: 'dashboard')
    exists(css: '#navigation .js-menu .js-dashboardMenuItem.is-active')
    exists_not(css: '#navigation .tasks .js-item.is-active')

    execute(js: 'App.Event.trigger("ui:rerender")')
    sleep 1
    verify_title(value: 'dashboard')
    exists(css: '#navigation .js-menu .js-dashboardMenuItem.is-active')
    exists_not(css: '#navigation .tasks .js-item.is-active')

    reload()
    sleep 2
    verify_title(value: 'dashboard')
    exists(css: '#navigation .js-menu .js-dashboardMenuItem.is-active')
    exists_not(css: '#navigation .tasks .js-item.is-active')

    execute(js: 'App.Event.trigger("ui:rerender")')
    sleep 1
    verify_title(value: 'dashboard')
    exists(css: '#navigation .js-menu .js-dashboardMenuItem.is-active')
    exists_not(css: '#navigation .tasks .js-item.is-active')

    # click on admin
    click(css: 'a[href = "#manage"]')
    verify_title(value: 'Users')
    exists_not(css: '#navigation .js-menu .is-active')
    exists_not(css: '#navigation .tasks .js-item.is-active')

    execute(js: 'App.Event.trigger("ui:rerender")')
    sleep 1
    verify_title(value: 'Users')
    exists_not(css: '#navigation .js-menu .is-active')
    exists_not(css: '#navigation .tasks .js-item.is-active')

    reload()
    sleep 2
    verify_title(value: 'Users')
    exists_not(css: '#navigation .js-menu .is-active')
    exists_not(css: '#navigation .tasks .js-item.is-active')

    execute(js: 'App.Event.trigger("ui:rerender")')
    sleep 1
    verify_title(value: 'Users')
    exists_not(css: '#navigation .js-menu .is-active')
    exists_not(css: '#navigation .tasks .js-item.is-active')

  end

end
