# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'browser_test_helper'

class AdminPermissionsGranularVsFullTest < TestCase
  def test_permissions_selecting
    new_group_name = "permissions_test_group#{rand(99_999_999)}"
    @browser = browser_instance
    login(
      username: 'master@example.com',
      password: 'test',
      url:      browser_url,
    )
    tasks_close_all()

    click(css: 'a[href="#manage"]')
    click(css: '.content.active a[href="#manage/groups"]')
    click(css: '.content.active a[data-type="new"]')

    modal_ready

    element = @browser.find_element(css: '.modal input[name=name]')
    element.clear
    element.send_keys(new_group_name)
    click(css: '.modal button.js-submit')
    modal_disappear

    click(css: '.content.active a[href="#manage/users"]')

    user_css = '.user-list .js-tableBody tr td'
    watch_for(css: user_css)
    @browser.find_elements(css: '.content.active .user-list td:first-child').each do |entry|
      next if entry.text.strip != 'master@example.com'

      entry.click
      break
    end

    modal_ready

    scroll_script = "var el = document.getElementsByClassName('modal')[0];"
    scroll_script += 'el.scrollTo(0, el.scrollHeight);'
    @browser.execute_script scroll_script

    group = @browser.find_elements(css: '.modal .settings-list tbody tr').find do |el|
      el.find_element(css: 'td').text == new_group_name
    end

    if !group
      screenshot(comment: 'group_not_found')
      raise "Can't find group #{new_group_name}"
    end

    toggle_checkbox(group, 'full')
    sleep(1)
    assert(checkbox_is_selected(group, 'full'))

    toggle_checkbox(group, 'read')
    sleep(1)
    assert(!checkbox_is_selected(group, 'full'))
    assert(checkbox_is_selected(group, 'read'))

    toggle_checkbox(group, 'full')
    sleep(1)
    assert(checkbox_is_selected(group, 'full'))
    assert(!checkbox_is_selected(group, 'read'))
  end
end
