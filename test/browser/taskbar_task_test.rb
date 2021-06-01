# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'browser_test_helper'

class TaskbarTaskTest < TestCase
  def test_persistant_task_a
    @browser = browser_instance
    login(
      username: 'agent1@example.com',
      password: 'test',
      url:      browser_url,
    )
    tasks_close_all()

    # persistant task
    click(css: 'a[href="#new"]', only_if_exists: true)
    click(css: 'a[href="#ticket/create"]', wait: 0.8)
    set(
      css:   '.active .newTicket input[name="title"]',
      value: 'some test AAA',
    )
    sleep 4
  end

  def test_persistant_task_b
    @browser = browser_instance
    login(
      username: 'agent1@example.com',
      password: 'test',
      url:      browser_url,
    )
    sleep 3

    # check if task still exists
    click(css: '.task', wait: 0.8)

    match(
      css:   '.active .newTicket input[name="title"]',
      value: 'some test AAA',
    )

    tasks_close_all()

    exists_not(css: '.active .newTicket input[name="title"]')
  end

  def test_persistant_task_with_relogin
    @browser = browser_instance
    login(
      username: 'agent1@example.com',
      password: 'test',
      url:      browser_url,
    )
    tasks_close_all()

    click(css: 'a[href="#new"]', only_if_exists: true)
    click(css: 'a[href="#ticket/create"]', wait: 0.8)
    set(
      css:   '.active .newTicket input[name="title"]',
      value: 'INBOUND TEST#1',
    )
    set(
      css:   '.active .newTicket [data-name="body"]',
      value: 'INBOUND BODY TEST#1',
    )
    sleep 2

    click(css: 'a[href="#new"]', only_if_exists: true)
    click(css: 'a[href="#ticket/create"]', wait: 0.8)
    set(
      css:   '.active .newTicket input[name="title"]',
      value: 'OUTBOUND TEST#1',
    )
    set(
      css:   '.active .newTicket [data-name="body"]',
      value: 'OUTBOUND BODY TEST#1',
    )
    sleep 3

    logout()
    sleep 4

    # relogin with master - task are not viewable
    login(
      username: 'master@example.com',
      password: 'test',
      url:      browser_url,
    )
    sleep 3

    match_not(
      css:   'body',
      value: 'INBOUND TEST#1',
    )
    match_not(
      css:   'body',
      value: 'OUTBOUND TEST#1',
    )
    logout()
    sleep 2

    match_not(
      css:   'body',
      value: 'INBOUND TEST#1',
    )
    match_not(
      css:   'body',
      value: 'OUTBOUND TEST#1',
    )

    # relogin with agent - task are viewable
    login(
      username: 'agent1@example.com',
      password: 'test',
      url:      browser_url,
    )
    sleep 3

    match(
      css:   'body',
      value: 'INBOUND TEST#1',
    )
    match(
      css:   'body',
      value: 'OUTBOUND TEST#1',
    )
  end
end
