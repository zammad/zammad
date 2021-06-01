# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'browser_test_helper'

# Regression test for UI bugfix
# https://github.com/zammad/zammad/issues/1669
#
# After creating a new ticket template, logging out, and logging back in,
# ensure that the template selection menu still contains the new entry.
class AgentTicketCreateTemplateTest < TestCase
  def test_ticket_template_creation
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
    watch_for(
      css:       '.active .templates-welcome',
      displayed: true
    )

    set(
      css:   'input[name="title"]',
      value: 'my first ticket'
    )
    click(
      css: '.active .templates-welcome .js-create'
    )
    watch_for(
      css:       '.active .templates-manage',
      displayed: true,
      timeout:   3,
    )
    exists_not(
      css: '.active .templates-manage select[name="id"] > option:not([value=""])'
    )

    # save new template
    set(
      css:   '.active .templates-manage .js-name',
      value: 'test template'
    )
    click(
      css: '.active .templates-manage .js-save'
    )
    exists(
      css:       '.active .templates-manage select[name="id"] > option:not([value=""])',
      displayed: true
    )

    # check if relogin temlates are still available
    logout
    login(
      username: 'agent1@example.com',
      password: 'test',
    )

    click(
      css: '.navigation > .tasks > a.task'
    )
    exists(
      css:       '.active .templates-manage',
      displayed: true
    )
    exists(
      css:       '.active .templates-manage select[name="id"] > option:not([value=""])',
      displayed: true
    )

    # apply new tempalte
    tasks_close_all()
    click(
      css: 'a[href="#ticket/create"]'
    )
    watch_for(
      css:       '.active .templates-manage',
      displayed: true,
      timeout:   3,
    )
    select(
      css:   '.active .templates-manage select[name="id"]',
      value: 'test template',
    )
    click(
      css: '.active .templates-manage .js-apply'
    )
    exists(
      css:   '.active .newTicket input[name="title"]',
      value: 'my first ticket'
    )
  end
end
