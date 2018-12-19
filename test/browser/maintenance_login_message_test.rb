require 'browser_test_helper'

class MaintenanceLoginMessageTest < TestCase

  def test_login_message
    browser1 = browser_instance
    login(
      browser:  browser1,
      username: 'master@example.com',
      password: 'test',
      url:      browser_url,
    )

    click(
      browser: browser1,
      css:     'a[href="#manage"]',
    )
    click(
      browser: browser1,
      css:     'a[href="#system/maintenance"]',
    )

    string  = rand(99_999_999_999_999_999).to_s
    message = "test <b>#{string}</b>"
    set(
      browser: browser1,
      css:     '.content.active .js-loginPreview [data-name="message"]',
      value:   message,
    )
    click(
      browser: browser1,
      css:     '#global-search',
    )

    browser2 = browser_instance
    location(
      browser: browser2,
      url:     browser_url,
    )
    exists_not(
      browser: browser2,
      css:     '.js-maintenanceLogin',
    )

    switch(
      browser: browser1,
      css:     '.content.active .js-loginSetting',
      type:    'on',
    )

    watch_for(
      browser: browser2,
      css:     '.js-maintenanceLogin',
      value:   message
    )

    switch(
      browser: browser1,
      css:     '.content.active .js-loginSetting',
      type:    'off',
    )

    watch_for_disappear(
      browser: browser2,
      css:     '.js-maintenanceLogin',
      timeout: 30,
    )
  end

end
