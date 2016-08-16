# encoding: utf-8
require 'browser_test_helper'

class MaintenanceTest < TestCase
  def test_message
    string       = rand(99_999_999_999_999_999).to_s
    title_html   = "test <b>#{string}</b>"
    title_text   = "test <b>#{string}<\/b>"
    message_html = "message <b>1äöüß</b> #{string}\n\n\nhttp://zammad.org"
    message_text = "message <b>1äöüß</b> #{string}\n\n\nhttp://zammad.org"

    # check #1
    browser1 = browser_instance
    login(
      browser: browser1,
      username: 'master@example.com',
      password: 'test',
      url: browser_url,
    )

    browser2 = browser_instance
    login(
      browser: browser2,
      username: 'agent1@example.com',
      password: 'test',
      url: browser_url,
    )
    click(
      browser: browser1,
      css: 'a[href="#manage"]',
    )
    click(
      browser: browser1,
      css: 'a[href="#system/maintenance"]',
    )

    set(
      browser: browser1,
      css: '#content .js-Message input[name="head"]',
      value: title_html,
    )
    set(
      browser: browser1,
      css: '#content .js-Message .js-textarea[data-name="message"]',
      value: message_html,
    )

    click(
      browser: browser1,
      css: '#content .js-Message button.js-submit',
    )

    watch_for(
      browser: browser2,
      css: '.modal',
      value: title_text,
    )
    watch_for(
      browser: browser2,
      css: '.modal',
      value: message_text,
    )

    match_not(
      browser: browser1,
      css: 'body',
      value: message_text,
    )

    click(
      browser: browser2,
      css: 'div.modal-header .js-close',
    )

    # check #2
    click(
      browser: browser1,
      css: 'a[href="#manage"]',
    )
    click(
      browser: browser1,
      css: 'a[href="#system/maintenance"]',
    )

    set(
      browser: browser1,
      css: '#content .js-Message input[name="head"]',
      value: title_html + ' #2',
    )
    set(
      browser: browser1,
      css: '#content .js-Message .js-textarea[data-name="message"]',
      value: message_html + ' #2',
    )

    click(
      browser: browser1,
      css: '#content .js-Message button.js-submit',
    )

    watch_for(
      browser: browser2,
      css: '.modal',
      value: title_text + ' #2',
    )
    watch_for(
      browser: browser2,
      css: '.modal',
      value: message_text + ' #2',
    )

    match_not(
      browser: browser1,
      css: 'body',
      value: message_text,
    )

    click(
      browser: browser2,
      css: 'div.modal-header .js-close',
    )

    # check #3
    click(
      browser: browser1,
      css: 'a[href="#manage"]',
    )
    click(
      browser: browser1,
      css: 'a[href="#system/maintenance"]',
    )

    set(
      browser: browser1,
      css: '#content .js-Message input[name="head"]',
      value: title_html + ' #3',
    )
    set(
      browser: browser1,
      css: '#content .js-Message .js-textarea[data-name="message"]',
      value: message_html + ' #3',
    )
    click(
      browser: browser1,
      css: '#content .js-Message input[name="reload"] + .icon-checkbox.icon-unchecked',
    )
    click(
      browser: browser1,
      css: '#content .js-Message button.js-submit',
    )

    watch_for(
      browser: browser2,
      css: '.modal',
      value: title_text + ' #3',
    )
    watch_for(
      browser: browser2,
      css: '.modal',
      value: message_text + ' #3',
    )
    watch_for(
      browser: browser2,
      css: '.modal',
      value: 'Continue session',
    )

    match_not(
      browser: browser1,
      css: 'body',
      value: message_text,
    )
  end

  def test_login_message
    browser1 = browser_instance
    login(
      browser: browser1,
      username: 'master@example.com',
      password: 'test',
      url: browser_url,
    )

    browser2 = browser_instance
    location(
      browser: browser2,
      url:     browser_url,
    )
    click(
      browser: browser1,
      css: 'a[href="#manage"]',
    )
    click(
      browser: browser1,
      css: 'a[href="#system/maintenance"]',
    )

    exists_not(
      browser: browser2,
      css: '.js-maintenanceLogin',
    )

    string  = rand(99_999_999_999_999_999).to_s
    message = "test <b>#{string}</b>"
    set(
      browser: browser1,
      css: '#content .js-loginPreview [data-name="message"]',
      value: message,
    )
    click(
      browser: browser1,
      css: '#global-search',
    )

    sleep 3
    switch(
      browser: browser1,
      css:  '#content .js-loginSetting',
      type: 'on',
    )

    watch_for(
      browser: browser2,
      css: '.js-maintenanceLogin',
      value: message
    )

    switch(
      browser: browser1,
      css:  '#content .js-loginSetting',
      type: 'off',
    )

    watch_for_disappear(
      browser: browser2,
      css: '.js-maintenanceLogin',
    )

  end

  def test_mode
    browser1 = browser_instance
    login(
      browser: browser1,
      username: 'master@example.com',
      password: 'test',
      url: browser_url,
    )

    browser2 = browser_instance
    location(
      browser: browser2,
      url:     browser_url,
    )
    click(
      browser: browser1,
      css: 'a[href="#manage"]',
    )
    click(
      browser: browser1,
      css: 'a[href="#system/maintenance"]',
    )

    exists_not(
      browser: browser2,
      css: '.js-maintenanceMode',
    )

    switch(
      browser:  browser1,
      css:      '#content .js-modeSetting',
      type:     'on',
      no_check: true,
    )

    # check warning
    alert = browser1.switch_to.alert
    #alert.dismiss()
    alert.accept()

    watch_for(
      browser: browser2,
      css: '.js-maintenanceMode',
    )

    # try to logon with normal agent, should not work
    login(
      browser: browser2,
      username: 'agent1@example.com',
      password: 'test',
      url: browser_url,
      success: false,
    )
    login(
      browser: browser2,
      username: 'nicole.braun@zammad.org',
      password: 'test',
      url: browser_url,
      success: false,
    )

    # logout with admin and logon again
    logout(
      browser: browser1,
    )
    sleep 4
    login(
      browser: browser1,
      username: 'master@example.com',
      password: 'test',
      url: browser_url,
    )
    click(
      browser: browser1,
      css: 'a[href="#manage"]',
    )
    click(
      browser: browser1,
      css: 'a[href="#system/maintenance"]',
    )

    switch(
      browser: browser1,
      css:  '#content .js-modeSetting',
      type: 'off',
    )

    watch_for_disappear(
      browser: browser2,
      css: '.js-maintenanceMode',
    )

    # try to logon with normal agent, should work again
    login(
      browser: browser2,
      username: 'agent1@example.com',
      password: 'test',
      url: browser_url,
    )
    logout(
      browser: browser2,
    )
    sleep 4
    login(
      browser: browser2,
      username: 'nicole.braun@zammad.org',
      password: 'test',
      url: browser_url,
    )

    switch(
      browser:  browser1,
      css:      '#content .js-modeSetting',
      type:     'on',
      no_check: true,
    )
    # check warning
    alert = browser1.switch_to.alert
    #alert.dismiss()
    alert.accept()

    watch_for(
      browser: browser2,
      css: '#login',
    )
    watch_for(
      browser: browser2,
      css: '.js-maintenanceMode',
    )

    switch(
      browser: browser1,
      css:  '#content .js-modeSetting',
      type: 'off',
    )

    watch_for_disappear(
      browser: browser2,
      css: '.js-maintenanceMode',
    )
  end

  def test_app_version
    @browser = browser_instance
    login(
      username: 'master@example.com',
      password: 'test',
      url: browser_url,
    )

    sleep 8

    execute(
      js: 'App.Event.trigger("maintenance", {type:"app_version", app_version:"1234:false"} )',
    )
    sleep 8

    match_not(
      css: 'body',
      value: 'new version',
    )

    execute(
      js: 'App.Event.trigger("maintenance", {type:"app_version", app_version:"1235:true"}) ',
    )
    sleep 5

    match(
      css: 'body',
      value: 'new version',
    )

  end

end
