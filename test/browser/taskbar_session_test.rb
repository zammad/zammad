# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'browser_test_helper'

class TaskbarSessionTest < TestCase
  def test_current_session_a_same_agent

    # check taken over session block screen with same user
    browser1 = browser_instance
    login(
      browser:  browser1,
      username: 'agent1@example.com',
      password: 'test',
      url:      browser_url,
    )

    browser2 = browser_instance
    login(
      browser:  browser2,
      username: 'agent1@example.com',
      password: 'test',
      url:      browser_url,
    )

    sleep 8

    match(
      browser: browser1,
      css:     'body',
      value:   'Continue session',
    )
    match_not(
      browser: browser2,
      css:     'body',
      value:   'Continue session',
    )

  end

  def test_current_session_b_different_agent

    # check taken over session block screen with same user
    browser1 = browser_instance
    login(
      browser:  browser1,
      username: 'master@example.com',
      password: 'test',
      url:      browser_url,
    )

    browser2 = browser_instance
    login(
      browser:  browser2,
      username: 'agent1@example.com',
      password: 'test',
      url:      browser_url,
    )

    sleep 8

    match_not(
      browser: browser1,
      css:     'body',
      value:   'Continue session',
    )
    match_not(
      browser: browser2,
      css:     'body',
      value:   'Continue session',
    )
  end

end
