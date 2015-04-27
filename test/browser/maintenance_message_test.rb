# encoding: utf-8
require 'browser_test_helper'

class MaintenanceMessageTest < TestCase
  def test_websocket
    string       = rand(99_999_999_999_999_999).to_s
    title_html   = "test <b>#{string}</b>"
    title_text   = "test <b>#{string}<\/b>"
    message_html = "message <b>1äöüß</b> #{string}\n\n\nhttp://zammad.org"
    message_text = "message <b>1äöüß<\/b> #{string}\n\nhttp:\/\/zammad.org"

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
      css: '#content input[name="head"]',
      value: title_html,
    )
    set(
      browser: browser1,
      css: '#content textarea[name="message"]',
      value: message_html,
    )

    click(
      browser: browser1,
      css: '#content button[type="submit"]',
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
      css: 'div.modal-header .close',
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
      css: '#content input[name="head"]',
      value: title_html + ' #2',
    )
    set(
      browser: browser1,
      css: '#content textarea[name="message"]',
      value: message_html + ' #2',
    )

    click(
      browser: browser1,
      css: '#content button[type="submit"]',
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
      css: 'div.modal-header .close',
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
      css: '#content input[name="head"]',
      value: title_html + ' #3',
    )
    set(
      browser: browser1,
      css: '#content textarea[name="message"]',
      value: message_html + ' #3',
    )
    check(
      browser: browser1,
      css: '#content input[name="reload"][value="1"]',
    )
    click(
      browser: browser1,
      css: '#content button[type="submit"]',
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
      value: 'Reload application',
    )

    match_not(
      browser: browser1,
      css: 'body',
      value: message_text,
    )
  end
end
