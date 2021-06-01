# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'browser_test_helper'

class MaintenanceModeTest < TestCase

  def test_mode
    browser1 = browser_instance
    login(
      browser:  browser1,
      username: 'master@example.com',
      password: 'test',
      url:      browser_url,
    )

    browser2 = browser_instance
    location(
      browser: browser2,
      url:     browser_url,
    )
    click(
      browser: browser1,
      css:     'a[href="#manage"]',
    )
    click(
      browser: browser1,
      css:     'a[href="#system/maintenance"]',
    )

    exists_not(
      browser: browser2,
      css:     '.js-maintenanceMode',
    )

    switch(
      browser:  browser1,
      css:      '.content.active .js-modeSetting',
      type:     'on',
      no_check: true,
    )

    # check warning
    modal_ready(browser: browser1)
    click(
      browser: browser1,
      css:     '.content.active .modal .js-submit',
    )
    modal_disappear(browser: browser1)

    watch_for(
      browser: browser2,
      css:     '.js-maintenanceMode',
    )

    # try to logon with normal agent, should not work
    login(
      browser:  browser2,
      username: 'agent1@example.com',
      password: 'test',
      url:      browser_url,
      success:  false,
    )
    login(
      browser:  browser2,
      username: 'nicole.braun@zammad.org',
      password: 'test',
      url:      browser_url,
      success:  false,
    )

    # logout with admin and logon again
    logout(
      browser: browser1,
    )
    sleep 4
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

    switch(
      browser: browser1,
      css:     '.content.active .js-modeSetting',
      type:    'off',
    )

    watch_for_disappear(
      browser: browser2,
      css:     '.js-maintenanceMode',
    )

    # try to logon with normal agent, should work again
    login(
      browser:  browser2,
      username: 'agent1@example.com',
      password: 'test',
      url:      browser_url,
    )
    logout(
      browser: browser2,
    )
    sleep 4
    login(
      browser:  browser2,
      username: 'nicole.braun@zammad.org',
      password: 'test',
      url:      browser_url,
    )

    switch(
      browser:  browser1,
      css:      '.content.active .js-modeSetting',
      type:     'on',
      no_check: true,
    )

    # check warning
    modal_ready(browser: browser1)
    click(
      browser: browser1,
      css:     '.content.active .modal .js-submit',
    )
    modal_disappear(browser: browser1)

    watch_for(
      browser: browser2,
      css:     '#login',
    )
    watch_for(
      browser: browser2,
      css:     '.js-maintenanceMode',
    )

    switch(
      browser: browser1,
      css:     '.content.active .js-modeSetting',
      type:    'off',
    )

    watch_for_disappear(
      browser: browser2,
      css:     '.js-maintenanceMode',
    )
  end

end
