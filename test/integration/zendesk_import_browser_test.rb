# encoding: utf-8
require 'browser_test_helper'

class ZendeskImportBrowserTest < TestCase
  def test_import

    if !ENV['IMPORT_BT_ZENDESK_ENDPOINT']
      raise "ERROR: Need IMPORT_BT_ZENDESK_ENDPOINT - hint IMPORT_BT_ZENDESK_ENDPOINT='https://example.zendesk.com/' (including trailing slash!)"
    end
    if !ENV['IMPORT_BT_ZENDESK_ENDPOINT_USERNAME']
      raise "ERROR: Need IMPORT_BT_ZENDESK_ENDPOINT_USERNAME - hint IMPORT_BT_ZENDESK_ENDPOINT_USERNAME='your@email.com'"
    end
    if !ENV['IMPORT_BT_ZENDESK_ENDPOINT_KEY']
      raise "ERROR: Need IMPORT_BT_ZENDESK_ENDPOINT_KEY - hint IMPORT_BT_ZENDESK_ENDPOINT_KEY='XYZ3133723421111'"
    end

    @browser = browser_instance
    location(url: browser_url)

    click(css: 'a[href="#import"]')

    click(css: 'a[href="#import/zendesk"]')

    set(
      css:   '#zendesk-url',
      value: 'https://reallybadexample.zendesk.com/'
    )

    sleep 5

    watch_for(
      css: '.zendesk-url-error',
      value: 'Hostname not found!',
    )

    set(
      css:   '#zendesk-url',
      value: ENV['IMPORT_BT_ZENDESK_ENDPOINT']
    )

    sleep 5

    watch_for_disappear(
      css: '.zendesk-url-error',
      value: 'Hostname not found!',
    )

    click(css: '.js-zendesk-credentials')

    set(
      css: '#zendesk-email',
      value: ENV['IMPORT_BT_ZENDESK_ENDPOINT_USERNAME']
    )

    set(
      css: '#zendesk-api-token',
      value: '1nv4l1dT0K3N'
    )

    sleep 5

    watch_for(
      css: '.zendesk-api-token-error',
      value: 'Invalid credentials!',
    )

    set(
      css: '#zendesk-api-token',
      value: ENV['IMPORT_BT_ZENDESK_ENDPOINT_KEY']
    )

    sleep 5

    watch_for_disappear(
      css: '.zendesk-url-error',
      value: 'Invalid credentials!',
    )

    click(css: '.js-migration-start')

    watch_for(
      css:     '.js-group .js-done',
      value:   '2',
      timeout: 60,
    )

    watch_for(
      css:     '.js-organization .js-done',
      value:   '1',
      timeout: 60,
    )

    watch_for(
      css:   '.js-user .js-done',
      value: '141',
      timeout: 60,
    )

    watch_for(
      css:     '.js-ticket .js-done',
      value:   '143',
      timeout: 600,
    )

    watch_for(
      css: 'body',
      value: 'login',
    )
  end
end
