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
    click( css: 'a[href="#current_user"]' )
    click( css: 'a[href="#profile"]' )
    click( css: 'a[href="#profile/language"]' )
    select(
      css: '.language_item [name="locale"]',
      value: 'English (United States)',
    )
    click( css: '.content button[type="submit"]' )
    sleep 2

    # change settings
    click( css: 'a[href="#manage"]' )
    click( css: 'a[href="#settings/security"]' )
    click( css: 'a[href="#third_party_auth"]' )
    sleep 2

    # set yes
    select(
      css: '#auth_facebook select[name="{boolean}auth_facebook"]',
      value: 'yes',
    )
    match(
      css: '#auth_facebook select[name="{boolean}auth_facebook"]',
      value: 'yes',
    )
    click( css: '#auth_facebook button[type=submit]' )
    watch_for(
      css: '#notify',
      value: 'update successful',
    )
    sleep 4
    match(
      css: '#auth_facebook select[name="{boolean}auth_facebook"]',
      value: 'yes',
    )
    match_not(
      css: '#auth_facebook select[name="{boolean}auth_facebook"]',
      value: 'no',
    )

    # set no
    select(
      css: '#auth_facebook select[name="{boolean}auth_facebook"]',
      value: 'no',
    )
    click( css: '#auth_facebook button[type=submit]' )
    watch_for(
      css: '#notify',
      value: 'update successful',
    )
    sleep 4
    match(
      css: '#auth_facebook select[name="{boolean}auth_facebook"]',
      value: 'no',
    )
    match_not(
      css: '#auth_facebook select[name="{boolean}auth_facebook"]',
      value: 'yes',
    )

    # set key and secret
    set(
      css: '#auth_facebook_credentials input[name=app_id]',
      value: 'id_test1234äöüß',
    )
    set(
      css: '#auth_facebook_credentials input[name=app_secret]',
      value: 'secret_test1234äöüß',
    )
    click( css: '#auth_facebook_credentials button[type=submit]' )
    watch_for(
      css: '#notify',
      value: 'update successful',
    )
    sleep 4
    match(
      css: '#auth_facebook_credentials input[name=app_id]',
      value: 'id_test1234äöüß',
    )
    match(
      css: '#auth_facebook_credentials input[name=app_secret]',
      value: 'secret_test1234äöüß',
    )

    # set key and secret again
    set(
      css: '#auth_facebook_credentials input[name=app_id]',
      value: '---',
    )
    set(
      css: '#auth_facebook_credentials input[name=app_secret]',
      value: '---',
    )
    click( css: '#auth_facebook_credentials button[type=submit]' )
    watch_for(
      css: '#notify',
      value: 'update successful',
    )
    sleep 4
    match(
      css: '#auth_facebook_credentials input[name=app_id]',
      value: '---',
    )
    match(
      css: '#auth_facebook_credentials input[name=app_secret]',
      value: '---',
    )

    reload()

    watch_for(
      css: '#auth_facebook_credentials input[name=app_id]',
      value: '---',
    )
    watch_for(
      css: '#auth_facebook_credentials input[name=app_secret]',
      value: '---',
    )
  end
end
