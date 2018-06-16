require 'browser_test_helper'

class IntegrationCtiTest < TestCase
  setup do
    if !ENV['CTI_TOKEN']
      raise "ERROR: Need CTI_TOKEN - hint CTI_TOKEN='some_token'"
    end

  end

  # Regression test for #2017
  def test_nav_menu_notification_badge_clears
    id = rand(99_999_999)

    @browser = browser_instance
    login(
      username: 'master@example.com',
      password: 'test',
      url: browser_url,
    )

    click(css: 'a[href="#manage"]')
    click(css: 'a[href="#system/integration"]')
    click(css: 'a[href="#system/integration/cti"]')

    switch(
      css: '.content.active .js-switch',
      type: 'on'
    )

    watch_for(
      css: 'a[href="#cti"]',
      timeout: 4,
    )

    click(css: 'a[href="#cti"]')

    call_counter = @browser.find_elements(css: '.js-phoneMenuItem .counter')
                           .first&.text.to_i

    # simulate cti callbacks
    url = URI.join(browser_url, "api/v1/cti/#{ENV['CTI_TOKEN']}")
    params = {
      direction: 'in',
      from: '491715000002',
      to: '4930600000000',
      callId: "4991155921769858278-#{id}",
      cause: 'busy'
    }
    Net::HTTP.post_form(url, params.merge(event: 'newCall'))
    Net::HTTP.post_form(url, params.merge(event: 'hangup'))

    watch_for(
      css: '.js-phoneMenuItem .counter',
      value: (call_counter + 1).to_s,
      timeout: 4,
    )

    check(css: '.content.active .table-checkbox input')

    watch_for_disappear(
      css: '.js-phoneMenuItem .counter',
      timeout: 6,
    )

    click(css: 'a[href="#manage"]')
    click(css: 'a[href="#system/integration"]')
    click(css: 'a[href="#system/integration/cti"]')

    switch(
      css: '.content.active .js-switch',
      type: 'off'
    )
  end

  # Regression test for #2018
  def test_e164_numbers_displayed_in_prettified_format
    id = rand(99_999_999)

    @browser = browser_instance
    login(
      username: 'master@example.com',
      password: 'test',
      url: browser_url,
    )

    click(css: 'a[href="#manage"]')
    click(css: 'a[href="#system/integration"]')
    click(css: 'a[href="#system/integration/cti"]')

    switch(
      css: '.content.active .js-switch',
      type: 'on'
    )

    watch_for(
      css: 'a[href="#cti"]'
    )

    click(css: 'a[href="#cti"]')

    # simulate cti callbacks...
    url = URI.join(browser_url, "api/v1/cti/#{ENV['CTI_TOKEN']}")

    # ...for private network number
    params = {
      direction: 'in',
      from: '007',
      to: '008',
      callId: "4991155921769858278-#{id}",
      cause: 'busy'
    }
    Net::HTTP.post_form(url, params.merge(event: 'newCall'))
    Net::HTTP.post_form(url, params.merge(event: 'hangup'))

    # ...for e164 number
    params = {
      direction: 'in',
      from: '4930609854180',
      to: '4930609811111',
      callId: "4991155921769858278-#{id.next}",
      cause: 'busy'
    }
    Net::HTTP.post_form(url, params.merge(event: 'newCall'))
    Net::HTTP.post_form(url, params.merge(event: 'hangup'))

    # view caller log
    click(css: 'a[href="#cti"]')

    # assertion: private network numbers appear verbatim
    watch_for(
      css: '.content.active .js-callerLog',
      value: '007',
      timeout: 3,
    )

    match(
      css: '.content.active .js-callerLog',
      value: '008',
    )

    # assertion: E164 numbers appear prettified
    match(
      css: '.content.active .js-callerLog',
      value: '+49 30 609854180',
    )

    match(
      css: '.content.active .js-callerLog',
      value: '+49 30 609811111',
    )
  end
end
