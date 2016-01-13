# encoding: utf-8
require 'browser_test_helper'

class OtrsImportBrowserTest < TestCase
  def test_import

    if !ENV['IMPORT_BT_OTRS_ENDPOINT']
      fail "ERROR: Need IMPORT_BT_OTRS_ENDPOINT - hint IMPORT_BT_OTRS_ENDPOINT='http://vz305.demo.znuny.com/otrs/public.pl?Action=ZammadMigrator'"
    end
    if !ENV['IMPORT_BT_OTRS_ENDPOINT_KEY']
      fail "ERROR: Need IMPORT_BT_OTRS_ENDPOINT_KEY - hint IMPORT_BT_OTRS_ENDPOINT_KEY='01234567899876543210'"
    end

    import_url = "#{ENV['IMPORT_BT_OTRS_ENDPOINT']};Key=#{ENV['IMPORT_BT_OTRS_ENDPOINT_KEY']}"

    @browser = browser_instance
    location(url: browser_url)

    click(css: 'a[href="#import"]')

    click(css: 'a[href="#import/otrs"]')

    click(css: '.js-download')

    click(css: '.js-otrs-link')

    set(
      css:   '#otrs-link',
      value: import_url
    )

    exists(
      css: 'svg.icon-checkmark'
    )

    click(css: '.js-migration-start')

    watch_for(
      css: 'body',
      value: 'login',
      timeout: 300,
    )

  end

end
