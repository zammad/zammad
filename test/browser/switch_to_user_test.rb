# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

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

    click(css: 'a[href="#manage"]')
    click(css: '.content.active a[href="#manage/users"]')

    set(
      css:   '.content.active .js-search',
      value: 'nicole',
    )
    sleep 3

    @browser.action.move_to(@browser.find_elements({ css: '.content.active .table-overview tbody tr:first-child' } )[0]).release.perform

    sleep 0.5
    click(
      css: '.content.active .dropdown--actions',
    )
    click(
      css: '.content.active .icon-switchView',
    )
    sleep 3

    watch_for(
      css:   '.switchBackToUser',
      value: 'zammad looks like',
    )
    watch_for(
      css:   '.switchBackToUser',
      value: 'Nicole',
    )
    login = @browser.find_elements({ css: '.user-menu .user a' })[0].attribute('title')
    assert_equal(login, 'nicole.braun@zammad.org')
    click(css: '.switchBackToUser .js-close')

    sleep 5
    login = @browser.find_elements({ css: '.user-menu .user a' })[0].attribute('title')
    assert_equal(login, 'master@example.com')

  end
end
