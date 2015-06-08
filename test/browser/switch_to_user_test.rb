# encoding: utf-8
require 'browser_test_helper'

class SwitchToUserTest < TestCase
  def test_agent_user
    @browser = browser_instance
    login(
      username: 'master@example.com',
      password: 'test',
      url:      browser_url,
    )
    tasks_close_all()

    click( css: 'a[href="#manage"]' )
    click( css: 'a[href="#manage/users"]' )

    set(
      css:   '#content .js-search',
      value: 'nicole',
    )
    sleep 3

    click(
      css: '#content .icon-user',
    )

    watch_for(
      :css     => '#app',
      :value   => 'zammad looks like',
    )
    login = @browser.find_elements( { css: '.user-menu .user a' } )[0].attribute('title')
    assert_equal(login, 'nicole.braun@zammad.org')

    click( css: '#app .js-close' )

    login = @browser.find_elements( { css: '.user-menu .user a' } )[0].attribute('title')
    assert_equal(login, 'master@example.com')

  end

end
