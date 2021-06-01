# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'browser_test_helper'

class PreferencesPermissionCheckTest < TestCase

  def test_permission_agent
    @browser = browser_instance
    login(
      username: 'master@example.com',
      password: 'test',
      url:      browser_url,
    )
    click(css: 'a[href="#current_user"]')
    click(css: 'a[href="#profile"]')
    match(
      css:   '.content .NavBarProfile',
      value: 'Password',
    )
    match(
      css:   '.content .NavBarProfile',
      value: 'Language',
    )
    match(
      css:   '.content .NavBarProfile',
      value: 'Notifications',
    )
    match(
      css:   '.content .NavBarProfile',
      value: 'Calendar',
    )
    match(
      css:   '.content .NavBarProfile',
      value: 'Token Access',
    )
  end

  def test_permission_customer
    @browser = browser_instance
    login(
      username: 'nicole.braun@zammad.org',
      password: 'test',
      url:      browser_url,
    )
    click(css: 'a[href="#current_user"]')
    click(css: 'a[href="#profile"]')
    match(
      css:   '.content .NavBarProfile',
      value: 'Password',
    )
    match(
      css:   '.content .NavBarProfile',
      value: 'Language',
    )
    match_not(
      css:   '.content .NavBarProfile',
      value: 'Notifications',
    )
    match_not(
      css:   '.content .NavBarProfile',
      value: 'Calendar',
    )
    match_not(
      css:   '.content .NavBarProfile',
      value: 'Token Access',
    )
  end

end
