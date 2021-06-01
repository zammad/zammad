# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'browser_test_helper'

class AgentTicketTextModuleTest < TestCase
  def test_text_modules
    random  = "text_module_test_#{rand(99_999_999)}"
    random2 = "text_module_test_#{rand(99_999_999)}"

    @browser = browser_instance
    login(
      username: 'master@example.com',
      password: 'test',
      url:      browser_url,
    )
    tasks_close_all()

    # create new text modules
    text_module_create(
      data: {
        name:     "some name#{random}",
        keywords: random,
        content:  "some content#{random}",
      },
    )
    text_module_create(
      data: {
        name:     "some name#{random2}",
        keywords: random2,
        content:  "some content#{random2}",
      },
    )

    # try to use them
    click(css: 'a[href="#new"]', only_if_exists: true)
    click(css: 'a[href="#ticket/create"]')
    sleep 2

    set(
      css:   '.active div[data-name=body]',
      value: "test ::#{random}",
    )
    watch_for(
      css:   '.active .shortcut',
      value: random,
    )
    sendkey(
      value: :arrow_down,
      slow:  true,
    )
    click(css: '.active .shortcut > ul> li')

    watch_for(
      css:   '.active div[data-name=body]',
      value: "some content#{random}",
    )
    tasks_close_all()

    # test with two browser windows
    random = "text_II_module_test_#{rand(99_999_999)}"

    user_rand = rand(99_999_999).to_s
    login     = "agent-text-module-#{user_rand}"
    firstname = "Text#{user_rand}"
    lastname  = "Module#{user_rand}"
    email     = "agent-text-module-#{user_rand}@example.com"
    password  = 'agentpw'

    # use current session
    browser1 = @browser

    browser2 = browser_instance
    login(
      browser:  browser2,
      username: 'agent1@example.com',
      password: 'test',
      url:      browser_url,
    )
    tasks_close_all(
      browser: browser2,
    )

    # create new ticket
    ticket_create(
      browser:       browser2,
      data:          {
        title: 'A',
      },
      do_not_submit: true,
    )
    ticket_create(
      browser:       browser2,
      data:          {
        title: 'B',
      },
      do_not_submit: true,
    )

    # create new text module
    text_module_create(
      browser: browser1,
      data:    {
        name:     "some name#{random}",
        keywords: random,
        content:  "some content \#{ticket.customer.lastname}#{random}",
      },
    )

    # create user to test placeholder
    user_create(
      browser: browser1,
      data:    {
        login:     login,
        firstname: firstname,
        lastname:  lastname,
        email:     email,
        password:  password,
      },
    )

    # check if text module exists in instance2, for ready to use
    set(
      browser: browser2,
      css:     '.active div[data-name=body]',
      value:   "test ::#{random}",
    )
    watch_for(
      browser: browser2,
      css:     '.active .shortcut',
      value:   random,
    )
    sendkey(
      browser: browser2,
      value:   :arrow_down,
    )
    click(
      browser: browser2,
      css:     '.active .shortcut > ul> li',
    )

    watch_for(
      browser: browser2,
      css:     '.active div[data-name=body]',
      value:   "some content -#{random}",
    )

    ticket_customer_select(
      browser:  browser2,
      css:      '.active .newTicket',
      customer: 'nicole',
    )

    set(
      browser: browser2,
      css:     '.active div[data-name=body]',
      value:   "::#{random}",
    )
    sendkey(
      browser: browser2,
      value:   :arrow_down,
      slow:    true,
    )
    click(
      browser: browser2,
      css:     '.active .shortcut > ul> li',
    )
    watch_for(
      browser: browser2,
      css:     '.active div[data-name=body]',
      value:   "some content Braun#{random}",
    )

    # verify zoom
    click(
      browser: browser1,
      css:     'a[href="#manage"]',
    )

    # create ticket
    ticket_create(
      browser: browser2,
      data:    {
        customer: 'nico',
        group:    'Users',
        title:    'some subject 123äöü',
        body:     'some body 123äöü',
      },
    )

    set(
      browser:  browser2,
      css:      '.active div[data-name=body]',
      value:    'test',
      no_click: true,
    )
    set(
      browser:  browser2,
      css:      '.active div[data-name=body]',
      value:    "::#{random}",
      no_click: true,
    )
    sendkey(
      browser: browser2,
      value:   :arrow_down,
    )
    sleep 1
    click(
      browser: browser2,
      css:     '.active .shortcut > ul> li',
    )

    watch_for(
      browser: browser2,
      css:     '.active div[data-name=body]',
      value:   "some content Braun#{random}",
    )

    # change customer
    click(
      browser: browser1,
      css:     'a[href="#manage"]',
    )
    click(
      browser: browser2,
      css:     '.active div[data-tab="ticket"] .js-actions .icon-arrow-down',
    )
    click(
      browser: browser2,
      css:     '.active div[data-tab="ticket"] .js-actions [data-type="customer-change"]',
    )

    modal_ready(browser: browser2)

    ticket_customer_select(
      browser:  browser2,
      css:      '.modal',
      customer: firstname,
    )

    click(
      browser: browser2,
      css:     '.modal-content .js-submit',
    )

    modal_disappear(browser: browser2)

    set(
      browser:  browser2,
      css:      '.active div[data-name=body]',
      value:    "::#{random}",
      no_click: true,
    )

    sendkey(
      browser: browser2,
      value:   :arrow_down,
    )

    sendkey(
      browser: browser2,
      value:   :enter,
    )

    watch_for(
      browser: browser2,
      css:     '.active div[data-name=body]',
      value:   "some content #{lastname}",
    )
  end
end
