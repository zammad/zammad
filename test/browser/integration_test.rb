# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'browser_test_helper'

class IntegrationTest < TestCase

  def test_sipgate
    @browser = browser_instance
    login(
      username: 'master@example.com',
      password: 'test',
      url:      browser_url,
    )
    tasks_close_all()

    # change settings
    click(css: 'a[href="#manage"]')
    click(css: 'a[href="#system/integration"]')
    click(css: 'a[href="#system/integration/sipgate"]')
    sleep 2
    switch(
      css:  '.content.active .main .js-switch',
      type: 'on',
    )
    set(
      css:   '.content.active .main .js-inboundBlockCallerId input[name=caller_id]',
      value: '041 1234567',
    )
    set(
      css:   '.content.active .main .js-inboundBlockCallerId input[name=note]',
      value: 'block spam caller id',
    )
    click(css: '.content.active .main .js-inboundBlockCallerId .js-add')
    click(css: '.content.active .main .js-submit')

    exists(
      css: '.content.active .main .js-inboundBlockCallerId [value="0411234567"]',
    )
    exists(
      css: '.content.active .main .js-inboundBlockCallerId [value="block spam caller id"]',
    )

    click(css: 'a[href="#dashboard"]')
    click(css: 'a[href="#manage"]')
    click(css: 'a[href="#system/integration"]')
    click(css: 'a[href="#system/integration/sipgate"]')

    exists(
      css: '.content.active .main .js-inboundBlockCallerId [value="0411234567"]',
    )
    exists(
      css: '.content.active .main .js-inboundBlockCallerId [value="block spam caller id"]',
    )

    reload()
    exists(
      css: '.content.active .main .js-inboundBlockCallerId [value="0411234567"]',
    )
    exists(
      css: '.content.active .main .js-inboundBlockCallerId [value="block spam caller id"]',
    )
    click(css: '.content.active .main .js-inboundBlockCallerId .js-remove')
    click(css: '.content.active .main .js-submit')
    sleep 6
    switch(
      css:  '.content.active .main .js-switch',
      type: 'off',
    )

    reload()
    exists_not(
      css: '.content.active .main .js-inboundBlockCallerId [value="0411234567"]',
    )
    exists_not(
      css: '.content.active .main .js-inboundBlockCallerId [value="block spam caller id"]',
    )
  end

  def test_slack
    @browser = browser_instance
    login(
      username: 'master@example.com',
      password: 'test',
      url:      browser_url,
    )
    tasks_close_all()

    # change settings
    click(css: 'a[href="#manage"]')
    click(css: 'a[href="#system/integration"]')
    click(css: 'a[href="#system/integration/slack"]')
    sleep 2
    switch(
      css:  '.content.active .main .js-switch',
      type: 'on',
    )
    click(css: '.content.active .main .checkbox-replacement')
    select(
      css:   '.content.active .main select[name="group_ids"]',
      value: 'Users',
    )
    set(
      css:   '.content.active .main input[name="webhook"]',
      value: 'http://some_url/webhook/123',
    )
    set(
      css:   '.content.active .main input[name="username"]',
      value: 'someuser',
    )

    click(css: '.content.active .main .js-submit')

    match(
      css:   '.content.active .main select[name="group_ids"]',
      value: 'Users',
    )
    match(
      css:   '.content.active .main input[name="webhook"]',
      value: 'http://some_url/webhook/123',
    )
    match(
      css:   '.content.active .main input[name="username"]',
      value: 'someuser',
    )

    click(css: 'a[href="#dashboard"]')
    click(css: 'a[href="#manage"]')
    click(css: 'a[href="#system/integration"]')
    click(css: 'a[href="#system/integration/slack"]')

    match(
      css:   '.content.active .main select[name="group_ids"]',
      value: 'Users',
    )
    match(
      css:   '.content.active .main input[name="webhook"]',
      value: 'http://some_url/webhook/123',
    )
    match(
      css:   '.content.active .main input[name="username"]',
      value: 'someuser',
    )

    reload()

    match(
      css:   '.content.active .main select[name="group_ids"]',
      value: 'Users',
    )
    match(
      css:   '.content.active .main input[name="webhook"]',
      value: 'http://some_url/webhook/123',
    )
    match(
      css:   '.content.active .main input[name="username"]',
      value: 'someuser',
    )

    switch(
      css:  '.content.active .main .js-switch',
      type: 'off',
    )
  end

  def test_clearbit
    @browser = browser_instance
    login(
      username: 'master@example.com',
      password: 'test',
      url:      browser_url,
    )
    tasks_close_all()

    # change settings
    click(css: 'a[href="#manage"]')
    click(css: 'a[href="#system/integration"]')
    click(css: 'a[href="#system/integration/clearbit"]')
    sleep 2
    switch(
      css:  '.content.active .main .js-switch',
      type: 'on',
    )
    set(
      css:   '.content.active .main input[name="api_key"]',
      value: 'some_api_key',
    )
    set(
      css:   '.content.active .main .js-userSync .js-new [name="source"]',
      value: 'source1',
    )
    set(
      css:   '.content.active .main .js-userSync .js-new [name="destination"]',
      value: 'destination1',
    )
    click(css: '.content.active .main .js-userSync .js-add')
    click(css: '.content.active .main .js-submit')

    click(css: 'a[href="#dashboard"]')
    click(css: 'a[href="#manage"]')
    click(css: 'a[href="#system/integration"]')
    click(css: 'a[href="#system/integration/clearbit"]')

    match(
      css:   '.content.active .main input[name="api_key"]',
      value: 'some_api_key',
    )
    exists(
      css: '.content.active .main .js-userSync [value="source1"]',
    )
    exists(
      css: '.content.active .main .js-userSync [value="destination1"]',
    )

    reload()

    match(
      css:   '.content.active .main input[name="api_key"]',
      value: 'some_api_key',
    )
    exists(
      css: '.content.active .main .js-userSync [value="source1"]',
    )
    exists(
      css: '.content.active .main .js-userSync [value="destination1"]',
    )

    switch(
      css:  '.content.active .main .js-switch',
      type: 'off',
    )

    set(
      css:   '.content.active .main input[name="api_key"]',
      value: '-empty-',
    )
    click(css: '.content.active .main .js-submit')

    reload()
    match_not(
      css:   '.content.active .main input[name="api_key"]',
      value: 'some_api_key',
    )
    match(
      css:   '.content.active .main input[name="api_key"]',
      value: '-empty-',
    )
    exists(
      css: '.content.active .main .js-userSync [value="source1"]',
    )
    exists(
      css: '.content.active .main .js-userSync [value="destination1"]',
    )
  end

  def test_icinga
    @browser = browser_instance
    login(
      username: 'master@example.com',
      password: 'test',
      url:      browser_url,
    )
    tasks_close_all()

    # change settings
    click(css: 'a[href="#manage"]')
    click(css: 'a[href="#system/integration"]')
    click(css: 'a[href="#system/integration/icinga"]')
    sleep 2
    switch(
      css:  '.content.active .main .js-switch',
      type: 'on',
    )
    set(
      css:   '.content.active .main input[name="icinga_sender"]',
      value: 'some@othersender.com',
    )
    select(
      css:   '.content.active .main select[name="icinga_auto_close"]',
      value: 'no',
    )
    click(css: '.content.active .main .js-submit')

    match(
      css:   '.content.active .main input[name="icinga_sender"]',
      value: 'some@othersender.com',
    )
    match(
      css:   '.content.active .main select[name="icinga_auto_close"]',
      value: 'no',
    )

    click(css: 'a[href="#dashboard"]')
    click(css: 'a[href="#manage"]')
    click(css: 'a[href="#system/integration"]')
    click(css: 'a[href="#system/integration/icinga"]')

    match(
      css:   '.content.active .main input[name="icinga_sender"]',
      value: 'some@othersender.com',
    )
    match(
      css:   '.content.active .main select[name="icinga_auto_close"]',
      value: 'no',
    )

    reload()

    match(
      css:   '.content.active .main input[name="icinga_sender"]',
      value: 'some@othersender.com',
    )
    match(
      css:   '.content.active .main select[name="icinga_auto_close"]',
      value: 'no',
    )

    switch(
      css:  '.content.active .main .js-switch',
      type: 'off',
    )
    set(
      css:   '.content.active .main input[name="icinga_sender"]',
      value: 'icinga@monitoring.example.com',
    )
    select(
      css:   '.content.active .main select[name="icinga_auto_close"]',
      value: 'yes',
    )
    click(css: '.content.active .main .js-submit')

    match(
      css:   '.content.active .main input[name="icinga_sender"]',
      value: 'icinga@monitoring.example.com',
    )
    match(
      css:   '.content.active .main select[name="icinga_auto_close"]',
      value: 'yes',
    )
  end
end
