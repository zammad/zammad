# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'browser_test_helper'

class AdminRoleTest < TestCase
  def test_role_device
    @browser = browser_instance
    login(
      username: 'master@example.com',
      password: 'test',
      url:      browser_url,
    )
    tasks_close_all()

    rand      = rand(99_999_999).to_s
    login     = "agent-role-#{rand}"
    firstname = "Role#{rand}"
    lastname  = "Module#{rand}"
    email     = "agent-role-#{rand}@example.com"
    password  = 'agentpw'

    user_create(
      data: {
        login:     login,
        firstname: firstname,
        lastname:  lastname,
        email:     email,
        password:  password,
      },
    )

    name = "somerole#{rand}"
    role_create(
      data: {
        name:              name,
        default_at_signup: false,
        permission:        [
          'admin.group',
          'user_preferences.device',
        ],
        member:            [login],
      }
    )

    logout()
    # flanky
    login(
      username: email,
      password: password,
      url:      browser_url,
    )
    tasks_close_all()
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
    match(
      css:   '.content .NavBarProfile',
      value: 'Devices',
    )

    logout()
    login(
      username: 'master@example.com',
      password: 'test',
      url:      browser_url,
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
      url:      browser_url,
    )
    tasks_close_all()
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
    match_not(
      css:   '.content .NavBarProfile',
      value: 'Devices',
    )
  end

  def test_role_admin_user

    @browser = browser_instance

    login(
      username: 'agent1@example.com',
      password: 'test',
      url:      browser_url,
    )

    # check if admin exists
    exists_not(css: '[href="#manage"]')
    logout()

    # add admin.user to agent role
    login(
      username: 'master@example.com',
      password: 'test',
      url:      browser_url,
    )
    tasks_close_all()

    role_edit(
      data: {
        name:       'Agent',
        active:     true,
        permission: {
          'admin.user'       => true,
          'chat.agent'       => true,
          'cti.agent'        => true,
          'ticket.agent'     => true,
          'user_preferences' => true,
        },
      }
    )
    logout()

    # check if admin exists
    login(
      username: 'agent1@example.com',
      password: 'test',
      url:      browser_url,
    )
    tasks_close_all()

    # create user
    random = rand(999_999_999)
    user_email = "admin.user.#{rand}@example.com"
    user_create(
      data: {
        #login:    "some login #{random}",
        firstname: "Admin.User Firstname #{random}",
        lastname:  "Admin.User Lastname #{random}",
        email:     user_email,
        password:  'some-pass',
      },
    )

    # create ticket for user
    ticket_create(
      data: {
        customer: user_email,
        group:    'Users',
        title:    'some changes',
        body:     'some body 123äöü - admin.user',
      },
    )

    # revoke admin.user
    logout()
    login(
      username: 'master@example.com',
      password: 'test',
      url:      browser_url,
    )
    tasks_close_all()

    role_edit(
      data: {
        name:       'Agent',
        active:     true,
        permission: {
          'admin.user'       => false,
          'chat.agent'       => true,
          'cti.agent'        => true,
          'ticket.agent'     => true,
          'user_preferences' => true,
        },
      }
    )
    logout()

    login(
      username: 'agent1@example.com',
      password: 'test',
      url:      browser_url,
    )

    # check if admin exists
    exists_not(css: '[href="#manage"]')

  end

  # regression test for issue #2332 - Role-Filter shows inactive Roles
  def test_inactive_roles_do_not_show_in_role_filter
    name = "some role #{rand(99_999_999)}"

    @browser = browser_instance
    login(
      username: 'master@example.com',
      password: 'test',
      url:      browser_url,
    )
    tasks_close_all()

    role_create(
      data: {
        name:   name,
        active: false
      }
    )

    click(
      css: '.content.active a[href="#manage/users"]',
    )

    # an inactive role should not appear in the role filter tabs
    match_not(
      css:   '.content.active .userSearch',
      value: name,
    )
  end
end
