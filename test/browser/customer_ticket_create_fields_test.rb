# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'browser_test_helper'

class CustomerTicketCreateFieldsTest < TestCase
  def test_customer_ticket_create_fields
    @browser = browser_instance

    # create agent session and fetch object attributes
    login(
      username: 'master@example.com',
      password: 'test',
      url:      browser_url,
    )
    # remove local object attributes bound to the session
    logout()

    # re-create agent session and fetch object attributes
    login(
      username: 'master@example.com',
      password: 'test',
      url:      browser_url,
    )
    # re-remove local object attributes bound to the session
    # there was an issue (#1856) where the old attribute values
    # persisted and were stored as the original attributes
    logout()

    # create customer session and fetch object attributes
    login(
      username: 'nicole.braun@zammad.org',
      password: 'test',
      url:      browser_url,
    )

    # customer ticket create
    click(css: 'a[href="#new"]', only_if_exists: true)
    click(css: 'a[href="#customer_ticket_new"]')
    sleep 2

    # ensure that the object attributes of the agent session
    # were removed properly and won't get displayed in the form
    exists_not(
      css: '.newTicket input[name="customer_id"]',
    )
  end
end
