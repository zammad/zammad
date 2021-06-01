# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'browser_test_helper'

class AuthTest < TestCase
  def test_authentication
    @browser = browser_instance
    location(url: browser_url)
    match(
      css:   '#login',
      value: 'username',
    )
    click(css: '#login button')

    sleep 4
    match(
      css:   '#login',
      value: 'username',
    )

    # login with username/password
    login(
      username: 'nicole.braun@zammad.org',
      password: 'test',
    )
    tasks_close_all()

    # reload page
    reload()

    # check if cookie is temporarily
    watch_for(
      css:   'body',
      value: 'Overviews',
    )

    # verify session cookie
    cookie(
      name:    '^_zammad.+?',
      value:   '.+?',
      expires: '',
    )
  end

  def test_authentication_new_browser_without_permanent_cookie_no_session_should_be
    @browser = browser_instance
    location(url: browser_url)
    match(
      css:   '#login',
      value: 'username',
    )
  end

  def test_new_browser_with_permanent_cookie_login
    @browser = browser_instance
    location(url: browser_url)

    # login with username/password
    login(
      username:    'nicole.braun@zammad.org',
      password:    'test',
      remember_me: true,
    )

    # check if cookie is temporarily
    watch_for(
      css:   'body',
      value: 'Overviews',
    )

    # verify session cookie
    cookie(
      name:    '^_zammad.+?',
      value:   '.+?',
      expires: '\d{4}-\d{1,2}-\d{1,2}.+?',
    )

    logout()

    # verify session cookie
    sleep 2
    cookie(
      name:    '^_zammad.+?',
      value:   '.+?',
      expires: '',
    )
  end

end
