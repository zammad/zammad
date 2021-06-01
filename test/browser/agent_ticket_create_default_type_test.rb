# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'browser_test_helper'

# Regression test for UI enhancement
# https://github.com/zammad/zammad/issues/1987
# Ensure that available ticket types are rendered correctly
class AgentTicketCreateDefaultTypeTest < TestCase
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
      css: '.type-tabs li[data-type=phone-in]'
    )

    exists(
      css: '.type-tabs li[data-type=phone-out]'
    )

    exists(
      css: '.type-tabs li[data-type=email-out]'
    )
  end

  def test_ticket_create_disabled_type
    @browser = browser_instance
    login(
      username: 'agent1@example.com',
      password: 'test',
      url:      browser_url,
    )
    tasks_close_all()

    @browser.execute_script("App.Config.set('ui_ticket_create_available_types', ['email-out', 'phone-out'])")

    click(
      css: 'a[href="#ticket/create"]'
    )

    exists_not(
      css: '.type-tabs li[data-type=phone-in]'
    )

    exists(
      css: '.type-tabs li[data-type=phone-out]'
    )

    exists(
      css: '.type-tabs li[data-type=email-out]'
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

    @browser.execute_script("App.Config.set('ui_ticket_create_available_types', ['email-out'])")

    click(
      css: 'a[href="#ticket/create"]'
    )

    exists_not(
      css: '.type-tabs'
    )
  end
end
