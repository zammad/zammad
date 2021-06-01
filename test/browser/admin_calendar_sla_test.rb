# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'browser_test_helper'

class AdminCalendarSlaTest < TestCase
  def test_calendar
    @browser = browser_instance
    login(
      username: 'master@example.com',
      password: 'test',
      url:      browser_url,
    )
    tasks_close_all()

    calendar_name = "ZZZ some calendar #{rand(99_999_999)}"
    sla_name = "ZZZ some sla #{rand(99_999_999)}"
    timezone = 'Europe/Berlin'
    timezone_verify = "Europe/Berlin\s\\(GMT\\+(2|1)\\)"
    calendar_create(
      data: {
        name:     calendar_name,
        timezone: timezone,
      }
    )

    # got to maintanance
    click(css: '[href="#manage"]')
    click(css: '[href="#system/maintenance"]')
    watch_for(
      css:     '.content.active',
      value:   'Enable or disable the maintenance mode',
      timeout: 4,
    )

    # go back
    click(css: '[href="#manage"]')
    click(css: '[href="#manage/calendars"]')
    watch_for(
      css:     '.content.active',
      value:   calendar_name,
      timeout: 4,
    )

    logout()

    login(
      username: 'master@example.com',
      password: 'test',
    )

    # check if admin exists
    click(css: '[href="#manage"]')
    click(css: '[href="#manage/calendars"]')
    watch_for(
      css:     '.content.active',
      value:   calendar_name,
      timeout: 4,
    )

    #@browser.execute_script('$(\'.content.active table tr td:contains(" ' + data[:name] + '")\').first().click()')
    @browser.execute_script('$(\'.content.active .main .js-edit\').last().click()')

    modal_ready(browser: @browser)
    watch_for(
      css:     '.content.active .modal input[name=name]',
      value:   calendar_name,
      timeout: 4,
    )
    watch_for(
      css:     '.content.active .modal input.js-input',
      value:   timezone_verify,
      timeout: 4,
    )
    modal_close()

    sla_create(
      data: {
        name:                        sla_name,
        calendar:                    "#{calendar_name} - #{timezone}",
        first_response_time_in_text: 61
      },
    )

  end
end
