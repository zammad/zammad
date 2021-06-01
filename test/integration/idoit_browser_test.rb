# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'browser_test_helper'

class IntegrationIdoitTest < TestCase

  def test_idoit_objects_corrects_saves_on_ticket_creation
    # Read i-doit credentials from ENV
    if !ENV['IDOIT_API_TOKEN']
      raise "ERROR: Need IDOIT_API_TOKEN - hint IDOIT_API_TOKEN='1234'"
    end

    api_token = ENV['IDOIT_API_TOKEN']
    if !ENV['IDOIT_API_ENDPOINT']
      raise "ERROR: Need IDOIT_API_ENDPOINT - hint IDOIT_API_ENDPOINT='1234'"
    end

    api_endpoint = ENV['IDOIT_API_ENDPOINT']
    if !ENV['IDOIT_API_CATEGORY']
      raise "ERROR: Need IDOIT_API_CATEGORY - hint IDOIT_API_CATEGORY='Building'"
    end

    api_category = ENV['IDOIT_API_CATEGORY']

    @browser = browser_instance
    login(
      username:    'master@example.com',
      password:    'test',
      url:         browser_url,
      auto_wizard: true,
    )

    # turn on i-doit integration
    click(css: 'a[href="#manage"]')
    click(css: 'a[href="#system/integration"]')
    click(css: 'a[href="#system/integration/idoit"]')
    switch(
      css:  '.content.active .js-switch',
      type: 'on'
    )

    # fill in i-doit login details
    set(
      css:   '.content.active .main input[name="api_token"]',
      value: api_token,
    )
    set(
      css:   '.content.active .main input[name="endpoint"]',
      value: api_endpoint,
    )
    click(css: '.content.active .main .js-submit')

    watch_for(
      css:   '#notify',
      value: 'update successful',
    )

    # new create a new ticket with an i-doit object
    ticket_create(
      data:          {
        customer: 'nico',
        group:    'Users',
        title:    'subject - i-doit integration #1',
        body:     'body - i-doit integration',
      },
      do_not_submit: true,
    )

    # open the i-doit selection modal
    click(css: '.content.active .tabsSidebar svg.icon-printer')
    click(css: '.content.active .sidebar[data-tab="idoit"] .js-headline')
    click(css: '.content.active .sidebar[data-tab="idoit"] .dropdown-menu')

    # wait for the API call to populate the dropdown menu
    watch_for(css: '.content.active .modal form input.js-input')
    # open the dropdown menu and choose the Building option
    click(css: '.content.active .modal form input.js-input')
    click(css: ".content.active .modal form li.js-option[title='#{api_category}']")
    # wait for the building results to populate from the API
    watch_for(css: '.content.active .modal form.js-result table.table')

    # click the check box from the first row and note its entry ID
    checkbox = @browser.find_elements(css: '.content.active .modal form.js-result tbody :first-child input')[0]
    entry_id = checkbox.attribute('value')
    checkbox.click()

    # submit the i-doit object selections
    click(css: '.content.active .modal form button.js-submit')

    # confirm that the entry have been successfully recorded
    watch_for(
      css: ".content.active .sidebar[data-tab='idoit'] a[href='#{api_endpoint}/?objID=#{entry_id}']",
    )

    # reselect the customer and verify if object is still shown in sidebar
    ticket_customer_select(
      css:      '.content.active .newTicket',
      customer: 'master',
    )

    watch_for(
      css: ".content.active .sidebar[data-tab='idoit'] a[href='#{api_endpoint}/?objID=#{entry_id}']",
    )

    # now submit the ticket
    click(css: '.content.active .newTicket button.js-submit')

    watch_for(
      css: '.content.active .ticketZoom-header .ticket-number',
    )

    watch_for(
      css: ".content.active .sidebar[data-tab='idoit'] a[href='#{api_endpoint}/?objID=#{entry_id}']",
    )

    tasks_close_all()

    # new create a new ticket with an i-doit object
    ticket_create(
      data:          {
        customer: 'nico',
        group:    'Users',
        title:    'subject - i-doit integration #2',
        body:     'body - i-doit integration',
      },
      do_not_submit: true,
    )

    # open the i-doit selection modal
    click(css: '.content.active .tabsSidebar svg.icon-printer')
    click(css: '.content.active .sidebar[data-tab="idoit"] .js-headline')
    click(css: '.content.active .sidebar[data-tab="idoit"] .dropdown-menu')

    # wait for the API call to populate the dropdown menu
    watch_for(css: '.content.active .modal form input.js-input')
    # open the dropdown menu and choose the Building option
    click(css: '.content.active .modal form input.js-input')
    click(css: ".content.active .modal form li.js-option[title='#{api_category}']")
    # wait for the building results to populate from the API
    watch_for(css: '.content.active .modal form.js-result table.table')

    # click the check box from the first row and note its entry ID
    checkbox = @browser.find_elements(css: '.content.active .modal form.js-result tbody :first-child input')[0]
    entry_id = checkbox.attribute('value')
    checkbox.click()

    # submit the i-doit object selections
    click(css: '.content.active .modal form button.js-submit')

    # confirm that the entry have been successfully recorded
    watch_for(
      css: ".content.active .sidebar[data-tab='idoit'] a[href='#{api_endpoint}/?objID=#{entry_id}']",
    )

    # now submit the ticket
    click(css: '.content.active .newTicket button.js-submit')

    watch_for(
      css: '.content.active .ticketZoom-header .ticket-number',
    )

    # open the i-doit sidebar again and verify that the entry is still there
    click(css: '.content.active .tabsSidebar .tabsSidebar-tab[data-tab="idoit"]')
    watch_for(
      css: ".content.active .sidebar[data-tab='idoit'] a[href='#{api_endpoint}/?objID=#{entry_id}']",
    )

    # remove i-doit object
    click(css: ".content.active .sidebar[data-tab='idoit'] .js-delete[data-object-id=\"#{entry_id}\"]")
    watch_for_disappear(
      css: ".content.active .sidebar[data-tab='idoit'] a[href='#{api_endpoint}/?objID=#{entry_id}']",
    )

    # reload browser and check if it's still removed
    sleep 3
    reload()
    watch_for(
      css: '.content.active .ticketZoom-header .ticket-number',
    )
    click(css: '.content.active .tabsSidebar .tabsSidebar-tab[data-tab="idoit"]')
    watch_for(
      css: ".content.active .sidebar[data-tab='idoit'] .sidebar-content",
    )
    match(
      css:   ".content.active .sidebar[data-tab='idoit'] .sidebar-content",
      value: 'none',
    )
    exists_not(
      css: ".content.active .sidebar[data-tab='idoit'] a[href='#{api_endpoint}/?objID=#{entry_id}']",
    )

    # add item again
    click(css: '.content.active .sidebar[data-tab="idoit"] .js-actions .dropdown-toggle')
    click(css: '.content.active .sidebar[data-tab="idoit"] .js-actions [data-type="objects-change"]')
    modal_ready()

    # wait for the API call to populate the dropdown menu
    watch_for(css: '.content.active .modal form input.js-input')
    # open the dropdown menu and choose the Building option
    click(css: '.content.active .modal form input.js-input')
    click(css: ".content.active .modal form li.js-option[title='#{api_category}']")
    # wait for the building results to populate from the API
    watch_for(css: '.content.active .modal form.js-result table.table')

    # click the check box from the first row and note its entry ID
    checkbox = @browser.find_elements(css: '.content.active .modal form.js-result tbody :first-child input')[0]
    entry_id = checkbox.attribute('value')
    checkbox.click()

    # submit the i-doit object selections
    click(css: '.content.active .modal form button.js-submit')

    # confirm that the entry have been successfully recorded
    watch_for(
      css: ".content.active .sidebar[data-tab='idoit'] a[href='#{api_endpoint}/?objID=#{entry_id}']",
    )

    # reload browser and check if it's still removed
    sleep 3
    reload()
    watch_for(
      css: '.content.active .ticketZoom-header .ticket-number',
    )

    # open the i-doit sidebar again and verify that the entry is still there
    click(css: '.content.active .tabsSidebar .tabsSidebar-tab[data-tab="idoit"]')
    watch_for(
      css: ".content.active .sidebar[data-tab='idoit'] a[href='#{api_endpoint}/?objID=#{entry_id}']",
    )

    # finally turn off i-doit integration
    click(css: 'a[href="#manage"]')
    click(css: 'a[href="#system/integration"]')
    click(css: 'a[href="#system/integration/idoit"]')

    switch(
      css:  '.content.active .js-switch',
      type: 'off'
    )
  end
end
