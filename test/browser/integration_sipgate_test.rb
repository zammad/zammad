# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'browser_test_helper'

class IntegrationSipgateTest < TestCase
  # Regression test for #2017
  def test_nav_menu_notification_badge_clears
    id = rand(99_999_999)

    @browser = browser_instance
    login(
      username: 'master@example.com',
      password: 'test',
      url:      browser_url,
    )

    click(css: 'a[href="#manage"]')
    click(css: 'a[href="#system/integration"]')
    click(css: 'a[href="#system/integration/sipgate"]')

    switch(
      css:  '.content.active .js-switch',
      type: 'on'
    )

    watch_for(
      css:     'a[href="#cti"]',
      timeout: 4,
    )

    click(css: 'a[href="#cti"]')

    call_counter = @browser.find_elements(css: '.js-phoneMenuItem .counter')
                           .first&.text.to_i

    # simulate cti callbacks
    url = URI.join(browser_url, 'api/v1/sipgate/in')
    params = {
      direction: 'in',
      from:      '491715000003',
      to:        '4930600000004',
      callId:    "4991155921769858279-#{id}",
      cause:     'busy'
    }
    Net::HTTP.post_form(url, params.merge(event: 'newCall'))
    Net::HTTP.post_form(url, params.merge(event: 'hangup'))

    # flanky
    watch_for(
      css:     '.js-phoneMenuItem .counter',
      value:   (call_counter + 1).to_s,
      timeout: 4,
    )

    check(css: '.content.active .table-checkbox input')

    watch_for_disappear(
      css:     '.js-phoneMenuItem .counter',
      timeout: 6,
    )

    click(css: 'a[href="#manage"]')
    click(css: 'a[href="#system/integration"]')
    click(css: 'a[href="#system/integration/sipgate"]')

    switch(
      css:  '.content.active .js-switch',
      type: 'off'
    )
  end
end
