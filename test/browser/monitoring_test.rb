# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'browser_test_helper'

class MonitoringTest < TestCase

  def test_mode
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
      css:     'a[href="#system/monitoring"]',
    )

    token = browser1.find_elements(css: '.active.content .js-token')[0].attribute('value')
    url = browser1.find_elements(css: '.active.content .js-url')[0].attribute('value')

    assert_match(token.to_s, url)

    click(
      browser: browser1,
      css:     '.active.content .js-resetToken',
    )
    sleep 3

    token_new = browser1.find_elements(css: '.active.content .js-token')[0].attribute('value')
    url_new = browser1.find_elements(css: '.active.content .js-url')[0].attribute('value')

    assert_not_equal(token, token_new)
    assert_not_equal(url, url_new)
    assert_match(token_new.to_s, url_new)

  end

end
