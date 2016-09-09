# encoding: utf-8
require 'browser_test_helper'

class AdminRoleTest < TestCase
  def test_role
    name = "some role #{rand(99_999_999)}"

    @browser = browser_instance
    login(
      username: 'master@example.com',
      password: 'test',
      url: browser_url,
    )
    tasks_close_all()

    rand      = rand(99_999_999).to_s
    login     = 'agent-role-' + rand
    firstname = 'Role' + rand
    lastname  = 'Module' + rand
    email     = 'agent-role-' + rand + '@example.com'
    password  = 'agentpw'

    user_create(
      data: {
        login: login,
        firstname: firstname,
        lastname: lastname,
        email: email,
        password: password,
      },
    )

    name = "somerole#{rand}"
    role_create(
      data: {
        name:              name,
        default_at_signup: false,
        permission: [
          'admin.group',
          'user_preferences.device',
        ],
        member: [login],
      }
    )

    logout()
    login(
      username: email,
      password: password,
      url: browser_url,
    )
    tasks_close_all()
    click(css: 'a[href="#current_user"]')
    click(css: 'a[href="#profile"]')
    match(
      css: '.content .NavBarProfile',
      value: 'Password',
    )
    match(
      css: '.content .NavBarProfile',
      value: 'Language',
    )
    match_not(
      css: '.content .NavBarProfile',
      value: 'Notifications',
    )
    match_not(
      css: '.content .NavBarProfile',
      value: 'Calendar',
    )
    match_not(
      css: '.content .NavBarProfile',
      value: 'Token Access',
    )
    match(
      css: '.content .NavBarProfile',
      value: 'Devices',
    )

    logout()
    login(
      username: 'master@example.com',
      password: 'test',
      url: browser_url,
    )
    role_edit(
      data: {
        name:   name,
        active: false,
      }
    )

    logout()
    login(
      username: email,
      password: password,
      url: browser_url,
    )
    tasks_close_all()
    click(css: 'a[href="#current_user"]')
    click(css: 'a[href="#profile"]')
    match(
      css: '.content .NavBarProfile',
      value: 'Password',
    )
    match(
      css: '.content .NavBarProfile',
      value: 'Language',
    )
    match_not(
      css: '.content .NavBarProfile',
      value: 'Notifications',
    )
    match_not(
      css: '.content .NavBarProfile',
      value: 'Calendar',
    )
    match_not(
      css: '.content .NavBarProfile',
      value: 'Token Access',
    )
    match_not(
      css: '.content .NavBarProfile',
      value: 'Devices',
    )
  end

end
