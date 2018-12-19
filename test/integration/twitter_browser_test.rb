require 'browser_test_helper'

class TwitterBrowserTest < TestCase
  def test_add_config

    @browser = browser_instance
    login(
      username:    'master@example.com',
      password:    'test',
      url:         browser_url,
      auto_wizard: true,
    )
    tasks_close_all()

    click(css: 'a[href="#manage"]')
    click(css: '.content.active a[href="#channels/twitter"]')
    click(css: '.content.active .js-configApp')
    sleep 2
    set(
      css:   '.content.active .modal [name=consumer_key]',
      value: 'some_key',
    )
    set(
      css:   '.content.active .modal [name=consumer_secret]',
      value: 'some_secret',
    )
    click(css: '.content.active .modal .js-submit')

    watch_for(
      css:   '.content.active .modal .alert',
      value: '401 Authorization Required',
    )

    set(
      css:   '.content.active .modal [name=oauth_token]',
      value: 'some_oauth_token',
    )

    set(
      css:   '.content.active .modal [name=oauth_token_secret]',
      value: 'some_oauth_token_secret',
    )

    set(
      css:   '.content.active .modal [name=env]',
      value: 'some_env',
    )

    click(css: '.content.active .modal .js-submit')

    watch_for(
      css:   '.content.active .modal .alert',
      value: '401 Authorization Required',
    )

  end
end
