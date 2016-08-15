# encoding: utf-8
require 'browser_test_helper'

class SettingTest < TestCase
  def test_setting
    @browser = browser_instance
    login(
      username: 'master@example.com',
      password: 'test',
      url: browser_url,
    )
    tasks_close_all()

    # make sure, that we have english frontend
    click(css: 'a[href="#current_user"]')
    click(css: 'a[href="#profile"]')
    click(css: 'a[href="#profile/language"]')
    select(
      css: '.language_item [name="locale"]',
      value: 'English (United States)',
    )
    click(css: '.content button[type="submit"]')
    sleep 2

    # change settings
    click(css: 'a[href="#manage"]')
    click(css: 'a[href="#settings/security"]')
    click(css: 'a[href="#third_party_auth"]')
    sleep 2
    switch(
      css: '#content .js-setting[data-name="auth_facebook"]',
      type: 'off',
    )

    browser2 = browser_instance
    location(
      browser: browser2,
      url: browser_url,
    )
    watch_for(
      browser: browser2,
      css: 'body',
      value: 'login',
    )
    match_not(
      browser: browser2,
      css: 'body',
      value: 'facebook',
    )

    # set yes
    switch(
      css: '#content .js-setting[data-name="auth_facebook"]',
      type: 'on',
    )

    # set key and secret
    set(
      css: '[data-name="auth_facebook_credentials"] input[name=app_id]',
      value: 'id_test1234äöüß',
    )
    set(
      css: '[data-name="auth_facebook_credentials"] input[name=app_secret]',
      value: 'secret_test1234äöüß',
    )
    click( css: '[data-name="auth_facebook_credentials"] button[type=submit]')
    watch_for(
      css: '#notify',
      value: 'update successful',
    )
    sleep 4
    match(
      css: '[data-name="auth_facebook_credentials"] input[name=app_id]',
      value: 'id_test1234äöüß',
    )
    match(
      css: '[data-name="auth_facebook_credentials"] input[name=app_secret]',
      value: 'secret_test1234äöüß',
    )

    # verify login page
    sleep 2
    watch_for(
      browser: browser2,
      css: 'body',
      value: 'facebook',
    )

    # set key and secret again
    set(
      css: '[data-name="auth_facebook_credentials"] input[name=app_id]',
      value: '---',
    )
    set(
      css: '[data-name="auth_facebook_credentials"] input[name=app_secret]',
      value: '---',
    )
    click(css: '[data-name="auth_facebook_credentials"] button[type=submit]')
    watch_for(
      css: '#notify',
      value: 'update successful',
    )
    sleep 4
    match(
      css: '[data-name="auth_facebook_credentials"] input[name=app_id]',
      value: '---',
    )
    match(
      css: '[data-name="auth_facebook_credentials"] input[name=app_secret]',
      value: '---',
    )

    reload()

    click(css: 'a[href="#settings/security"]')
    click(css: 'a[href="#third_party_auth"]')
    watch_for(
      css: '[data-name="auth_facebook_credentials"] input[name=app_id]',
      value: '---',
    )
    watch_for(
      css: '[data-name="auth_facebook_credentials"] input[name=app_secret]',
      value: '---',
    )
    sleep 2
    switch(
      css: '#content .js-setting[data-name="auth_facebook"]',
      type: 'off',
    )

    sleep 2
    watch_for(
      browser: browser2,
      css: 'body',
      value: 'login',
    )
    match_not(
      browser: browser2,
      css: 'body',
      value: 'facebook',
    )
  end
end
