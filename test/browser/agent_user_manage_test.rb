# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'browser_test_helper'

class AgentUserManageTest < TestCase
  def test_agent_customer_ticket_create
    random_number       = SecureRandom.uuid
    customer_user_email = "customer-test-#{random_number}@example.com"
    firstname           = "Customer Firstname #{random_number}"
    lastname            = 'Customer Lastname'
    fullname            = "\"#{firstname} #{lastname}\" <#{customer_user_email}>"

    @browser = browser_instance
    login(
      username: 'agent1@example.com',
      password: 'test',
      url:      browser_url,
    )
    tasks_close_all

    # create customer
    click(css: 'a[href="#new"]', only_if_exists: true)
    click(css: 'a[href="#ticket/create"]')

    await_text(text: 'New Ticket')

    # Rumors say there is a modal reaper which will kill your modals if you dont sleep before a new ticket create
    sleep 3

    click(css: '.content.active .newTicket [name="customer_id_completion"]')

    # check if pulldown is open, it's not working stable via selenium
    @browser.execute_script("$('.active .newTicket .js-recipientDropdown').addClass('open')")

    sleep 1
    sendkey(value: :arrow_down)
    sleep 0.5
    click(css: '.content.active .newTicket .recipientList-entry.js-objectNew')

    modal_ready
    set(
      css:   '.content.active .modal input[name="firstname"]',
      value: firstname,
    )
    set(
      css:   '.content.active .modal input[name="lastname"]',
      value: lastname,
    )
    set(
      css:   '.content.active .modal input[name="email"]',
      value: customer_user_email,
    )

    click(css: '.content.active .modal button.js-submit')
    modal_disappear

    sleep 4

    # check is used to check selected
    match(
      css:      '.content.active .newTicket input[name="customer_id"]',
      value:    '^\d+$',
      no_quote: true,
    )
    match(
      css:   '.content.active .newTicket input[name="customer_id_completion"]',
      value: firstname,
    )
    match(
      css:   '.content.active .newTicket input[name="customer_id_completion"]',
      value: lastname,
    )
    match(
      css:   '.content.active .newTicket input[name="customer_id_completion"]',
      value: customer_user_email,
    )
    match(
      css:   '.content.active .newTicket input[name="customer_id_completion"]',
      value: fullname,
    )

    # call new ticket screen again
    tasks_close_all

    # wait for user get indexed in elastic search
    await_global_search(query: random_number)

    click(css: 'a[href="#new"]', only_if_exists: true)
    click(css: 'a[href="#ticket/create"]')

    watch_for(
      css:     '.content.active .newTicket',
      timeout: 1,
    )

    match(
      css:   '.content.active .newTicket input[name="customer_id"]',
      value: '',
    )
    match(
      css:   '.content.active .newTicket input[name="customer_id_completion"]',
      value: '',
    )
    set(
      css:   '.content.active .newTicket input[name="customer_id_completion"]',
      value: customer_user_email,
    )
    sleep 3

    click(css: '.content.active .newTicket .recipientList-entry.js-object.is-active')
    sleep 1

    # check is used to check selected
    match(
      css:      '.content.active .newTicket input[name="customer_id"]',
      value:    '^\d+$',
      no_quote: true,
    )
    match(
      css:   '.content.active .newTicket input[name="customer_id_completion"]',
      value: firstname,
    )
    match(
      css:   '.content.active .newTicket input[name="customer_id_completion"]',
      value: lastname,
    )
    match(
      css:   '.content.active .newTicket input[name="customer_id_completion"]',
      value: customer_user_email,
    )
    match(
      css:   '.content.active .newTicket input[name="customer_id_completion"]',
      value: fullname,
    )
  end

  def test_agent_customer_ticket_zoom
    customer_user_email = "customer-test-#{SecureRandom.uuid}@example.com"
    firstname           = 'Customer Firstname'
    lastname            = 'Customer Lastname'
    fullname            = "#{firstname} #{lastname} <#{customer_user_email}>"

    @browser = browser_instance
    login(
      username: 'agent1@example.com',
      password: 'test',
      url:      browser_url,
    )
    tasks_close_all

    ticket_create(
      data: {
        customer: 'nico',
        group:    'Users',
        title:    'some changes',
        body:     'some body',
      },
    )

    watch_for(
      css:   '.content.active .ticketZoom-header .ticket-number',
      value: '\d',
    )

    click(css: '.content.active .tabsSidebar-tabs .tabsSidebar-tab[data-tab="customer"]')

    match(
      css:   '.content.active .tabsSidebar .sidebar[data-tab="customer"]',
      value: 'Nicole Braun',
    )

    click(css: '.content.active .tabsSidebar .sidebar[data-tab="customer"] .js-actions')
    click(css: '.content.active .tabsSidebar .sidebar[data-tab="customer"] .js-actions li[data-type="customer-change"]')

    modal_ready
    click(css: '.content.active .modal [name="customer_id_completion"]')

    # check if pulldown is open, it's not working stable via selenium
    @browser.execute_script("$('.active .modal .js-recipientDropdown').addClass('open')")

    sleep 1
    sendkey(value: :arrow_down)
    sleep 0.5
    click(css: '.content.active .modal .recipientList-entry.js-objectNew')

    watch_for(
      css:     '.content.active .modal input[name="firstname"]',
      timeout: 1,
    )

    set(
      css:   '.content.active .modal input[name="firstname"]',
      value: firstname,
    )
    set(
      css:   '.content.active .modal input[name="lastname"]',
      value: lastname,
    )
    set(
      css:   '.content.active .modal input[name="email"]',
      value: customer_user_email,
    )

    # there are 2 models, take the correct one
    # click(css: '.content.active .modal button.js-submit')
    @browser.execute_script("$('.content.active .modal input[name=\"firstname\"]').closest('form').find('button.js-submit').trigger('click')")

    # check is used to check selected
    watch_for(
      css:      '.content.active .modal input[name="customer_id"]',
      value:    '^\d+$',
      no_quote: true,
    )
    match(
      css:   '.content.active .modal input[name="customer_id_completion"]',
      value: firstname,
    )
    match(
      css:   '.content.active .modal input[name="customer_id_completion"]',
      value: lastname,
    )
    match(
      css:   '.content.active .modal input[name="customer_id_completion"]',
      value: customer_user_email,
    )
    match(
      css:   '.content.active .modal input[name="customer_id_completion"]',
      value: fullname,
    )

    click(css: '.content.active .modal button.js-submit')
    modal_disappear

    watch_for(
      css:     '.content.active .tabsSidebar .sidebar[data-tab="customer"]',
      value:   customer_user_email,
      timeout: 4,
    )

  end

end
