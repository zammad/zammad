# encoding: utf-8
require 'browser_test_helper'

class OtrsImportBrowserTest < TestCase
  def test_import
    @browser = browser_instance
    location(url: browser_url)

    watch_for(
      css: 'body',
      value: 'xxxx',
      timeout: 10,
    )

    # click import

    # click otrs

    # enter otrs url + key

    # watch for import start

    # watch for import end

  end

end
