# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'browser_test_helper'

# Regression test for UI enhancement
# https://github.com/zammad/zammad/issues/1987
# Ensure that available ticket types are rendered correctly
class AgentTicketCreateAvailableTypesTest < TestCase
  def test_ticket_create_type
    @browser = browser_instance
    login(
      username: 'agent1@example.com',
      password: 'test',
      url:      browser_url,
    )
    tasks_close_all()

    click(
      css: 'a[href="#ticket/create"]'
    )

    exists(
      css: '.type-tabs li.active[data-type=phone-in]'
    )
  end

  def test_ticket_create_solo_type
    @browser = browser_instance
    login(
      username: 'agent1@example.com',
      password: 'test',
      url:      browser_url,
    )
    tasks_close_all()

    @browser.execute_script("App.Config.set('ui_ticket_create_default_type', 'email-out')")

    click(
      css: 'a[href="#ticket/create"]'
    )

    exists(
      css: '.type-tabs li.active[data-type=email-out]'
    )
  end
end
