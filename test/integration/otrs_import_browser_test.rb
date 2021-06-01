# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'browser_test_helper'

class OtrsImportBrowserTest < TestCase
  def test_import

    if !ENV['IMPORT_BT_OTRS_ENDPOINT']
      raise "ERROR: Need IMPORT_BT_OTRS_ENDPOINT - hint IMPORT_BT_OTRS_ENDPOINT='http://vz305.demo.znuny.com/otrs/public.pl?Action=ZammadMigrator'"
    end
    if !ENV['IMPORT_BT_OTRS_ENDPOINT_KEY']
      raise "ERROR: Need IMPORT_BT_OTRS_ENDPOINT_KEY - hint IMPORT_BT_OTRS_ENDPOINT_KEY='01234567899876543210'"
    end

    @browser = browser_instance
    location(url: browser_url)

    click(css: 'a[href="#import"]')
    click(css: 'a[href="#import/otrs"]')
    click(css: '.js-download')
    click(css: '.js-otrs-link')

    invalid_key_url = "#{ENV['IMPORT_BT_OTRS_ENDPOINT']};Key=31337"

    set(
      css:   '#otrs-link',
      value: invalid_key_url
    )
    sleep 5

    watch_for(
      css:   '.otrs-link-error',
      value: 'Invalid API key.',
    )

    import_url = "#{ENV['IMPORT_BT_OTRS_ENDPOINT']};Key=#{ENV['IMPORT_BT_OTRS_ENDPOINT_KEY']}"
    set(
      css:   '#otrs-link',
      value: import_url
    )
    sleep 5

    watch_for_disappear(
      css:   '.otrs-link-error',
      value: 'Invalid API key.',
    )
    click(css: '.js-migration-check')

    watch_for(
      css:   '.wizard-slide:not(.hide)',
      value: 'Notice',
    )
    click(css: '.js-migration-start')

    watch_for(
      css:     'body',
      value:   'login',
      timeout: 600,
    )

  end

end
