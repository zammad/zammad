# encoding: utf-8
require 'browser_test_helper'

class FacebookBrowserTest < TestCase
  def test_add_config

    # app config
    if !ENV['FACEBOOK_APP_ID']
      fail "ERROR: Need FACEBOOK_APP_ID - hint FACEBOOK_APP_ID='1234'"
    end
    app_id = ENV['FACEBOOK_APP_ID']
    if !ENV['FACEBOOK_APP_SECRET']
      fail "ERROR: Need FACEBOOK_APP_SECRET - hint FACEBOOK_APP_SECRET='1234'"
    end
    app_secret = ENV['FACEBOOK_APP_SECRET']
    if !ENV['FACEBOOK_USER_LOGIN']
      fail "ERROR: Need FACEBOOK_USER_LOGIN - hint FACEBOOK_USER_LOGIN='1234'"
    end
    user_login = ENV['FACEBOOK_USER_LOGIN']
    if !ENV['FACEBOOK_USER_PW']
      fail "ERROR: Need FACEBOOK_USER_PW - hint FACEBOOK_USER_PW='1234'"
    end
    user_pw = ENV['FACEBOOK_USER_PW']

    @browser = browser_instance
    login(
      username: 'master@example.com',
      password: 'test',
      url: browser_url,
      auto_wizard: true,
    )
    tasks_close_all()

    click(css: 'a[href="#manage"]')
    click(css: 'a[href="#channels/facebook"]')

    click(css: '#content .js-configApp')
    sleep 2
    set(
      css: '#content .modal [name=application_id]',
      value: app_id,
    )
    set(
      css: '#content .modal [name=application_secret]',
      value: 'wrong',
    )
    click(css: '#content .modal .js-submit')

    watch_for(
      css: '#content .modal .alert',
      value: 'Error',
    )

    set(
      css: '#content .modal [name=application_secret]',
      value: app_secret,
    )
    click(css: '#content .modal .js-submit')

    watch_for_disappear(
      css: '#content .modal .alert',
      value: 'Error',
    )

    watch_for(
      css: '#content .js-new',
      value: 'add account',
    )

    click(css: '#content .js-configApp')

    set(
      css: '#content .modal [name=application_secret]',
      value: 'wrong',
    )
    click(css: '#content .modal .js-submit')

    watch_for(
      css: '#content .modal .alert',
      value: 'Error',
    )

    set(
      css: '#content .modal [name=application_secret]',
      value: app_secret,
    )
    click(css: '#content .modal .js-submit')

    watch_for_disappear(
      css: '#content .modal .alert',
      value: 'Error',
    )

    watch_for(
      css: '#content .js-new',
      value: 'add account',
    )

    click(css: '#content .js-new')

    watch_for(
      css: 'body',
      value: '(Facebook Login|Log into Facebook)',
    )

    set(
      css: '#email',
      value: user_login,
    )
    set(
      css: '#pass',
      value: user_pw,
    )
    click(css: '#login_button_inline')

    #sleep 10
    #click(css: 'div[role="dialog"] button[type="submit"][name="__CONFIRM__"]')
    #sleep 10
    #click(css: 'div[role="dialog"] button[type="submit"][name="__CONFIRM__"]')
    #sleep 10

    #watch_for(
    #  css: '#content .modal',
    #  value: '',
    #)

    watch_for(
      css: '#navigation',
      value: 'Dashboard',
    )

    click(css: '#content .modal .js-close')

    watch_for(
      css: '#content',
      value: 'Hansi Merkur',
    )
    exists(
      css: '#content .main .action:nth-child(1)'
    )
    exists_not(
      css: '#content .main .action:nth-child(2)'
    )

    click(css: '#content .js-new')

    sleep 10

    #click(css: '#login_button_inline')

    #watch_for(
    #  css: '#content .modal',
    #  value: 'Search Terms',
    #)

    click(css: '#content .modal .js-close')

    watch_for(
      css: '#content',
      value: 'Hansi Merkur',
    )
    exists(
      css: '#content .main .action:nth-child(1)'
    )
    exists_not(
      css: '#content .main .action:nth-child(2)'
    )

  end

end
