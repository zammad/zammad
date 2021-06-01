# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'browser_test_helper'

class SignupPasswordChangeAndResetTest < TestCase
  def test_signup
    signup_user_email = "signup-test-#{rand(999_999)}@example.com"
    @browser = browser_instance
    location(url: browser_url)
    click(css: 'a[href="#signup"]')
    exists(css: '.signup')

    # signup
    set(
      css:   'input[name="firstname"]',
      value: 'Signup Firstname',
    )
    set(
      css:   'input[name="lastname"]',
      value: 'Signup Lastname',
    )
    set(
      css:   'input[name="email"]',
      value: signup_user_email,
    )
    set(
      css:   'input[name="password"]',
      value: 'SOme-pass1',
    )
    set(
      css:   'input[name="password_confirm"]',
      value: 'SOme-pass1',
    )
    click(css: 'button.js-submit')

    watch_for(
      css:   '.signup',
      value: 'Registration successful!',
    )

    # auto login via token trick in dev mode
    click(css: '.signup .js-submitResend')

    watch_for(
      css: '#login',
    )
    login(
      username: signup_user_email,
      password: 'SOme-pass1',
    )

    watch_for(
      css:   '.content.active',
      value: 'Welcome!',
    )

    # change password
    click(css: '.navbar-items-personal .user a')
    sleep 1
    click(css: 'a[href="#profile"]')
    click(css: 'a[href="#profile/password"]')
    set(
      css:   'input[name="password_old"]',
      value: 'nonexisiting',
    )
    set(
      css:   'input[name="password_new"]',
      value: 'some',
    )
    set(
      css:   'input[name="password_new_confirm"]',
      value: 'some',
    )
    click(css: '.content .btn--primary')

    watch_for(
      css:   'body',
      value: 'current password is wrong',
    )

    set(
      css:   'input[name="password_old"]',
      value: 'SOme-pass1',
    )
    set(
      css:   'input[name="password_new_confirm"]',
      value: 'some2',
    )
    click(css: '.content .btn--primary')
    watch_for(
      css:   'body',
      value: 'passwords do not match',
    )

    set(
      css:   'input[name="password_new"]',
      value: 'SOme-1',
    )
    set(
      css:   'input[name="password_new_confirm"]',
      value: 'SOme-1',
    )
    click(css: '.content .btn--primary')

    watch_for(
      css:   'body',
      value: 'it must be at least',
    )

    set(
      css:   'input[name="password_new"]',
      value: 'SOme-pass-new',
    )
    set(
      css:   'input[name="password_new_confirm"]',
      value: 'SOme-pass-new',
    )
    click(css: '.content .btn--primary')

    watch_for(
      css:   'body',
      value: 'must contain at least 1 digit',
    )

    set(
      css:   'input[name="password_new"]',
      value: 'SOme-pass-new2',
    )
    set(
      css:   'input[name="password_new_confirm"]',
      value: 'SOme-pass-new2',
    )
    click(css: '.content .btn--primary')

    watch_for(
      css:   'body',
      value: 'Password changed successfully',
    )
    logout()

    # check login with new pw
    login(
      username: signup_user_email,
      password: 'SOme-pass-new2',
    )
    logout()

    # reset password (not possible)
    location(url: "#{browser_url}/#password_reset_verify/not_existing_token")

    watch_for(
      css:   'body',
      value: 'Token is invalid',
    )

    # reset password (with valid session - should not be possible)
    login(
      username: signup_user_email,
      password: 'SOme-pass-new2',
      url:      browser_url,
    )

    location(url: "#{browser_url}/#password_reset")
    sleep 1

    match_not(
      css:   'body',
      value: 'password',
    )
    logout()

    # reset password (correct way)
    click(css: 'a[href="#password_reset"]')

    set(
      css:   'input[name="username"]',
      value: 'nonexisiting',
    )
    click(css: '.reset_password .btn--primary')
    watch_for(
      css:   'body',
      value: 'sent password reset instructions',
    )

    click(css: '.reset_password .btn--primary')

    set(
      css:   'input[name="username"]',
      value: signup_user_email,
    )
    click(css: '.reset_password .btn--primary')
    watch_for(
      css:   'body',
      value: 'sent password reset instructions',
    )

    # redirect to "#password_reset_verify/#{token}" url by app, because of "developer_mode"
    watch_for(
      css:   'body',
      value: 'Choose your new password',
    )

    # set new password
    set(
      css:   'input[name="password"]',
      value: 'some',
    )
    set(
      css:   'input[name="password_confirm"]',
      value: 'some2',
    )
    click(css: '.js-passwordForm .js-submit')
    watch_for(
      css:   'body',
      value: 'passwords do not match',
    )

    set(
      css:   'input[name="password"]',
      value: 'SOme-1',
    )
    set(
      css:   'input[name="password_confirm"]',
      value: 'SOme-1',
    )
    click(css: '.js-passwordForm .js-submit')
    watch_for(
      css:   'body',
      value: 'it must be at least',
    )

    set(
      css:   'input[name="password"]',
      value: 'SOme-pass-new',
    )
    set(
      css:   'input[name="password_confirm"]',
      value: 'SOme-pass-new',
    )
    click(css: '.js-passwordForm .js-submit')
    watch_for(
      css:   'body',
      value: 'must contain at least 1 digit',
    )

    set(
      css:   'input[name="password"]',
      value: 'SOme-pass-new2',
    )
    set(
      css:   'input[name="password_confirm"]',
      value: 'SOme-pass-new2',
    )
    click(css: '.js-passwordForm .js-submit')
    watch_for(
      css:   'body',
      value: 'Your password has been changed',
    )

    # check if user is logged in
    sleep 5
    match(
      css:       '.user-menu .user a',
      value:     signup_user_email,
      attribute: 'title',
    )

  end
end
