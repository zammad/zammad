require 'browser_test_helper'

# Regression test for #2017

class PhoneNotifyNotClearingOnLeftsideTest < TestCase
  def test_notify_badge
    id = rand(99_999_999)

    @browser = browser_instance
    login(
      username: 'master@example.com',
      password: 'test',
      url: browser_url,
    )

    click(css: 'a[href="#manage"]')
    click(css: 'a[href="#system/integration"]')
    click(css: 'a[href="#system/integration/sipgate"]')

    if !@browser.find_element(css: 'input[name=sipgate_integration]').property('checked')
      switch(
        css: '.active .js-switch',
        type: 'on'
      )
    end

    watch_for(
      css: 'a[href="#cti"]'
    )

    click(css: 'a[href="#cti"]')

    # simulate sipgate callbacks

    url = URI.join(browser_url, 'api/v1/sipgate/in')
    params = { direction: 'in', from: '491715000002', to: '4930600000000', callId: "4991155921769858278-#{id}", cause: 'busy' }
    Net::HTTP.post_form(url, params.merge(event: 'newCall'))
    Net::HTTP.post_form(url, params.merge(event: 'hangup'))

    watch_for(
      css: '.js-phoneMenuItem .counter',
      value: '1'
    )

    @browser.find_element(css: '.table-checkbox label').click

    watch_for_disappear(
      css: '.js-phoneMenuItem .counter'
    )
  end
end
