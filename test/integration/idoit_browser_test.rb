
require 'browser_test_helper'

class IntegrationIdoitTest < TestCase

  def test_idoit_objects_corrects_saves_on_ticket_creation
    # Read I-doit credentials from ENV
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

    id = rand(99_999_999)
    @browser = instance = browser_instance
    login(
      username: 'master@example.com',
      password: 'test',
      url: browser_url,
    )

    # turn on I-doit integration
    click(css: 'a[href="#manage"]')
    click(css: 'a[href="#system/integration"]')
    click(css: 'a[href="#system/integration/idoit"]')
    switch(
      css: '.content.active .js-switch',
      type: 'on'
    )

    # fill in I-doit login details
    set(
      css: '.content.active .main input[name="api_token"]',
      value: api_token,
    )
    set(
      css: '.content.active .main input[name="endpoint"]',
      value: api_endpoint,
    )
    click(css: '.content.active .main .js-submit')

    watch_for(
      css: '#notify',
      value: 'update successful',
    )

    # new create a new ticket with an I-doit object
    ticket = ticket_create(
      data: {
        customer: 'nico',
        group: 'Users',
        title: 'subject - I-doit integration',
        body: 'body - I-doit integration',
      },
      do_not_submit: true,
    )

    # open the I-doit selection modal
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
    checkbox = instance.find_elements(css: '.content.active .modal form.js-result tbody :first-child input')[0]
    entry_id = checkbox.attribute('value')
    checkbox.click()

    # submit the I-doit object selections
    click(css: '.content.active .modal form button.js-submit')

    # confirm that the entry have been successfully recorded
    watch_for(
      css: ".content.active .sidebar[data-tab='idoit'] a[href='#{api_endpoint}/?objID=#{entry_id}']",
    )

    # now submit the ticket
    click(css: '.content.active .newTicket button.js-submit')
    sleep 5

    # open the I-doit sidebar again and verify that the entry is still there
    click(css: '.content.active .tabsSidebar svg.icon-printer')
    watch_for(
      css: ".content.active .sidebar[data-tab='idoit'] a[href='#{api_endpoint}/?objID=#{entry_id}']",
    )

    # finally turn off I-doit integration
    click(css: 'a[href="#manage"]')
    click(css: 'a[href="#system/integration"]')
    click(css: 'a[href="#system/integration/idoit"]')

    switch(
      css: '.content.active .js-switch',
      type: 'off'
    )
  end
end
