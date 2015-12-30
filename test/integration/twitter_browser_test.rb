# encoding: utf-8
require 'browser_test_helper'

class TwitterBrowserTest < TestCase
  def test_add_config

    # app config
    if !ENV['TWITTER_CONSUMER_KEY']
      fail "ERROR: Need TWITTER_CONSUMER_KEY - hint TWITTER_CONSUMER_KEY='1234'"
    end
    consumer_key = ENV['TWITTER_CONSUMER_KEY']
    if !ENV['TWITTER_CONSUMER_SECRET']
      fail "ERROR: Need TWITTER_CONSUMER_SECRET - hint TWITTER_CONSUMER_SECRET='1234'"
    end
    consumer_secret = ENV['TWITTER_CONSUMER_SECRET']

    if !ENV['TWITTER_USER_LOGIN']
      fail "ERROR: Need TWITTER_USER_LOGIN - hint TWITTER_USER_LOGIN='1234'"
    end
    twitter_user_loign = ENV['TWITTER_USER_LOGIN']

    if !ENV['TWITTER_USER_PW']
      fail "ERROR: Need TWITTER_USER_PW - hint TWITTER_USER_PW='1234'"
    end
    twitter_pw = ENV['TWITTER_USER_PW']

    @browser = browser_instance
    login(
      username: 'master@example.com',
      password: 'test',
      url: browser_url,
    )
    tasks_close_all()

    click(css: 'a[href="#manage"]')
    click(css: 'a[href="#channels/twitter"]')
    click(css: '#content .js-configApp')
    sleep 2
    set(
      css: '#content .modal [name=consumer_key]',
      value: consumer_key,
    )
    set(
      css: '#content .modal [name=consumer_secret]',
      value: 'wrong',
    )
    click(css: '#content .modal .js-submit')

    watch_for(
      css: '#content .modal .alert',
      value: 'Authorization Required',
    )

    set(
      css: '#content .modal [name=consumer_secret]',
      value: consumer_secret,
    )
    click(css: '#content .modal .js-submit')

    watch_for_disappear(
      css: '#content .modal .alert',
      value: 'Authorization Required',
    )

    watch_for(
      css: '#content .js-new',
      value: 'add account',
    )

    click(css: '#content .js-configApp')

    set(
      css: '#content .modal [name=consumer_secret]',
      value: 'wrong',
    )
    click(css: '#content .modal .js-submit')

    watch_for(
      css: '#content .modal .alert',
      value: 'Authorization Required',
    )

    set(
      css: '#content .modal [name=consumer_secret]',
      value: consumer_secret,
    )
    click(css: '#content .modal .js-submit')

    watch_for_disappear(
      css: '#content .modal .alert',
      value: 'Authorization Required',
    )

    watch_for(
      css: '#content .js-new',
      value: 'add account',
    )

    click(css: '#content .js-new')

    sleep 10

    set(
      css: '#username_or_email',
      value: twitter_user_loign,
    )
    set(
      css: '#password',
      value: twitter_pw,
    )
    click(css: '#allow')

    #watch_for(
    #  css: '.notice.callback',
    #  value: 'Redirecting you back to the application',
    #)

    watch_for(
      css: '#content .modal',
      value: 'Search Terms',
    )

    click(css: '#content .modal .js-close')

    watch_for(
      css: '#content',
      value: 'Armin Theo',
    )
    exists(
      css: '#content .main .action:nth-child(1)'
    )
    exists_not(
      css: '#content .main .action:nth-child(2)'
    )

    # add account again
    click(css: '#content .js-new')

    sleep 10

    click(css: '#allow')

    watch_for(
      css: '#content .modal',
      value: 'Search Terms',
    )

    click(css: '#content .modal .js-close')

    watch_for(
      css: '#content',
      value: 'Armin Theo',
    )
    exists(
      css: '#content .main .action:nth-child(1)'
    )
    exists_not(
      css: '#content .main .action:nth-child(2)'
    )

  end

end
