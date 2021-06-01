# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'browser_test_helper'

class AgentTicketCreateResetCustomerSelectionTest < TestCase
  def test_clear_customer
    @browser = browser_instance
    login(
      username: 'master@example.com',
      password: 'test',
      url:      browser_url,
    )
    tasks_close_all()

    click(css: 'a[href="#new"]', only_if_exists: true)
    click(css: 'a[href="#ticket/create"]')

    watch_for(
      css:     '.content.active .newTicket',
      timeout: 3,
    )

    exists(css: '.content.active .newTicket')
    exists(css: '.content.active .tabsSidebar .sidebar[data-tab="template"]')
    exists(css: '.content.active .tabsSidebar .tabsSidebar-tab.active[data-tab="template"]')

    exists_not(css: '.content.active .tabsSidebar .sidebar[data-tab="customer"]')
    exists_not(css: '.content.active .tabsSidebar .tabsSidebar-tab[data-tab="customer"]')

    click(css: '.content.active .newTicket [name="customer_id_completion"]')

    # check if pulldown is open, it's not working stable via selenium
    @browser.execute_script( "$('.content.active .newTicket .js-recipientDropdown').addClass('open')" )

    set(
      css:   '.content.active .newTicket input[name="customer_id_completion"]',
      value: 'nicole',
    )
    watch_for(
      css:     '.content.active .newTicket .js-recipientDropdown .recipientList.is-shown',
      value:   'Nicole',
      timeout: 3,
    )
    sendkey(value: :enter)
    sleep 1

    exists(css: '.content.active .newTicket')
    exists(css: '.content.active .tabsSidebar .sidebar[data-tab="template"]')
    exists(css: '.content.active .tabsSidebar .tabsSidebar-tab.active[data-tab="template"]')

    exists(css: '.content.active .tabsSidebar .sidebar[data-tab="customer"]')
    exists(css: '.content.active .tabsSidebar .tabsSidebar-tab[data-tab="customer"]')

    set(
      css:   '.content.active .newTicket input[name="customer_id_completion"]',
      value: '',
    )
    sendkey(value: :backspace)
    sleep 1

    exists(css: '.content.active .newTicket')
    exists(css: '.content.active .tabsSidebar .sidebar[data-tab="template"]')
    exists(css: '.content.active .tabsSidebar .tabsSidebar-tab.active[data-tab="template"]')

    exists_not(css: '.content.active .tabsSidebar .sidebar[data-tab="customer"]')
    exists_not(css: '.content.active .tabsSidebar .tabsSidebar-tab[data-tab="customer"]')

    set(
      css:   '.content.active .newTicket input[name="title"]',
      value: 'some title',
    )
    set(
      css:   '.content.active .newTicket div[data-name="body"]',
      value: 'some body',
    )
    select(
      css:   '.content.active .newTicket select[name="group_id"]',
      value: 'Users',
    )
    click(css: '.content.active .newTicket .js-submit')

    watch_for(
      css: '.content.active .newTicket .user_autocompletion.form-group.has-error',
    )

    # cleanup
    tasks_close_all()
  end

  def test_clear_customer_use_email
    @browser = browser_instance
    login(
      username: 'master@example.com',
      password: 'test',
      url:      browser_url,
    )
    tasks_close_all()

    click(css: 'a[href="#new"]', only_if_exists: true)
    click(css: 'a[href="#ticket/create"]')
    sleep 2

    exists(css: '.content.active .newTicket')
    exists(css: '.content.active .tabsSidebar .sidebar[data-tab="template"]')
    exists(css: '.content.active .tabsSidebar .tabsSidebar-tab.active[data-tab="template"]')

    exists_not(css: '.content.active .tabsSidebar .sidebar[data-tab="customer"]')
    exists_not(css: '.content.active .tabsSidebar .tabsSidebar-tab[data-tab="customer"]')

    click(css: '.content.active .newTicket [name="customer_id_completion"]')

    # check if pulldown is open, it's not working stable via selenium
    @browser.execute_script( "$('.content.active .newTicket .js-recipientDropdown').addClass('open')" )

    set(
      css:   '.content.active .newTicket input[name="customer_id_completion"]',
      value: 'nicole',
    )
    watch_for(
      css:     '.content.active .newTicket .js-recipientDropdown .recipientList.is-shown',
      value:   'Nicole',
      timeout: 3,
    )
    sendkey(value: :enter)
    sleep 1

    exists(css: '.content.active .newTicket')
    exists(css: '.content.active .tabsSidebar .sidebar[data-tab="template"]')
    exists(css: '.content.active .tabsSidebar .tabsSidebar-tab.active[data-tab="template"]')

    exists(css: '.content.active .tabsSidebar .sidebar[data-tab="customer"]')
    exists(css: '.content.active .tabsSidebar .tabsSidebar-tab[data-tab="customer"]')

    set(
      css:   '.content.active .newTicket input[name="customer_id_completion"]',
      value: '',
    )
    sendkey(value: :backspace)
    sleep 1

    exists(css: '.content.active .newTicket')
    exists(css: '.content.active .tabsSidebar .sidebar[data-tab="template"]')
    exists(css: '.content.active .tabsSidebar .tabsSidebar-tab.active[data-tab="template"]')

    exists_not(css: '.content.active .tabsSidebar .sidebar[data-tab="customer"]')
    exists_not(css: '.content.active .tabsSidebar .tabsSidebar-tab[data-tab="customer"]')

    set(
      css:   '.content.active .newTicket input[name="customer_id_completion"]',
      value: 'somecustomer_not_existing_right_now@example.com',
    )
    set(
      css:   '.content.active .newTicket input[name="title"]',
      value: 'some title',
    )
    set(
      css:   '.content.active .newTicket div[data-name="body"]',
      value: 'some body',
    )
    select(
      css:   '.content.active .newTicket select[name="group_id"]',
      value: 'Users',
    )
    click(css: '.content.active .newTicket .js-submit')

    watch_for(
      css:   '.content.active .ticketZoom-header .ticket-number',
      value: '\d',
    )

    click(css: '.content.active .tabsSidebar-tabs .tabsSidebar-tab[data-tab="customer"]')

    match(
      css:   '.content.active .tabsSidebar .sidebar[data-tab="customer"]',
      value: 'somecustomer_not_existing_right_now@example.com',
    )

    click(css: '.content.active .tabsSidebar .sidebar[data-tab="customer"] .js-actions')
    click(css: '.content.active .tabsSidebar .sidebar[data-tab="customer"] .js-actions li[data-type="customer-change"]')

    modal_ready()

    exists_not(
      css: '.content.active .modal .user_autocompletion.form-group.has-error',
    )

    click(css: '.content.active .modal .js-submit')

    watch_for(
      css: '.content.active .modal .user_autocompletion.form-group.has-error',
    )

    set(
      css:   '.content.active .modal input[name="customer_id_completion"]',
      value: 'master',
    )
    click(css: '.content.active .modal .js-submit')

    watch_for(
      css: '.content.active .modal .user_autocompletion.form-group.has-error',
    )

    set(
      css:   '.content.active .modal input[name="customer_id_completion"]',
      value: 'master',
    )
    watch_for(
      css:     '.content.active .modal .js-recipientDropdown .recipientList.is-shown',
      value:   'Master',
      timeout: 3,
    )
    sendkey(value: :enter)
    sleep 1

    set(
      css:   '.content.active .modal input[name="customer_id_completion"]',
      value: '',
    )
    sendkey(value: :backspace)
    sleep 1

    click(css: '.content.active .modal .js-submit')

    watch_for(
      css: '.content.active .modal .user_autocompletion.form-group.has-error',
    )

    set(
      css:   '.content.active .modal input[name="customer_id_completion"]',
      value: 'master',
    )
    watch_for(
      css:     '.content.active .modal .js-recipientDropdown .recipientList.is-shown',
      value:   'Master',
      timeout: 3,
    )
    sendkey(value: :enter)
    sleep 1

    click(css: '.content.active .modal .js-submit')
    #click(css: '.content.active .tabsSidebar-tabs .tabsSidebar-tab[data-tab="customer"]')

    watch_for(
      css:   '.content.active .tabsSidebar .sidebar[data-tab="customer"]',
      value: 'master@example.com',
    )

    # cleanup
    tasks_close_all()
  end
end
