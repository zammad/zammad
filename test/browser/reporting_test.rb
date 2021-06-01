# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'browser_test_helper'

class ReportingTest < TestCase
  def test_only_show_active_reporting_profiles
    @browser = browser_instance

    login(
      username: 'master@example.com',
      password: 'test',
      url:      browser_url,
    )
    tasks_close_all()

    report_profile_create(
      data: {
        name:   'active_report_profile',
        active: true,
      }
    )
    report_profile_create(
      data: {
        name:   'inactive_report_profile',
        active: false,
      }
    )

    click(
      css: 'a[href="#manage"]',
    )
    click(
      css: '.content.active a[href="#manage/report_profiles"]',
    )
    click(
      css:  'a[href="#report"]',
    )
    watch_for(
      css:  '.content ul.checkbox-list',
    )
    labels = @browser.find_elements(css: '.content ul.checkbox-list .label-text').map(&:text)
    assert_equal labels, %w[-all- active_report_profile]
  end
end
