# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'browser_test_helper'

class MaintenanceSessionMessageTest < TestCase
  def test_message
    string       = rand(99_999_999_999_999_999).to_s
    title_html   = "test <b>#{string}</b>"
    title_text   = "test <b>#{string}<\/b>"
    message_html = "message <b>1äöüß</b> #{string}\n\n\nhttps://zammad.org"
    message_text = "message <b>1äöüß</b> #{string}\n\n\nhttps://zammad.org"

    # check #1
    browser1 = browser_instance
    login(
      browser:  browser1,
      username: 'master@example.com',
      password: 'test',
      url:      browser_url,
    )

    browser2 = browser_instance
    login(
      browser:  browser2,
      username: 'agent1@example.com',
      password: 'test',
      url:      browser_url,
    )
    click(
      browser: browser1,
      css:     'a[href="#manage"]',
    )
    click(
      browser: browser1,
      css:     'a[href="#system/maintenance"]',
    )

    set(
      browser: browser1,
      css:     '.content.active .js-Message input[name="head"]',
      value:   title_html,
    )
    set(
      browser: browser1,
      css:     '.content.active .js-Message .js-textarea[data-name="message"]',
      value:   message_html,
    )

    click(
      browser: browser1,
      css:     '.content.active .js-Message button.js-submit',
    )

    modal_ready(browser: browser2)
    watch_for(
      browser: browser2,
      css:     '.modal',
      value:   title_text,
    )
    watch_for(
      browser: browser2,
      css:     '.modal',
      value:   message_text,
    )

    match_not(
      browser: browser1,
      css:     'body',
      value:   message_text,
    )

    click(
      browser: browser2,
      css:     'div.modal-header .js-close',
    )
    modal_disappear(browser: browser2)

    # check #2
    click(
      browser: browser1,
      css:     'a[href="#manage"]',
    )
    click(
      browser: browser1,
      css:     'a[href="#system/maintenance"]',
    )

    set(
      browser: browser1,
      css:     '.content.active .js-Message input[name="head"]',
      value:   "#{title_html} #2",
    )
    set(
      browser: browser1,
      css:     '.content.active .js-Message .js-textarea[data-name="message"]',
      value:   "#{message_html} #2",
    )

    click(
      browser: browser1,
      css:     '.content.active .js-Message button.js-submit',
    )

    modal_ready(browser: browser2)
    watch_for(
      browser: browser2,
      css:     '.modal',
      value:   "#{title_text} #2",
    )
    watch_for(
      browser: browser2,
      css:     '.modal',
      value:   "#{message_text} #2",
    )

    match_not(
      browser: browser1,
      css:     'body',
      value:   message_text,
    )

    click(
      browser: browser2,
      css:     'div.modal-header .js-close',
    )
    modal_disappear(browser: browser2)

    # check #3
    click(
      browser: browser1,
      css:     'a[href="#manage"]',
    )
    click(
      browser: browser1,
      css:     'a[href="#system/maintenance"]',
    )

    set(
      browser: browser1,
      css:     '.content.active .js-Message input[name="head"]',
      value:   "#{title_html} #3",
    )
    set(
      browser: browser1,
      css:     '.content.active .js-Message .js-textarea[data-name="message"]',
      value:   "#{message_html} #3",
    )
    click(
      browser: browser1,
      css:     '.content.active .js-Message input[name="reload"] + .icon-checkbox.icon-unchecked',
    )
    click(
      browser: browser1,
      css:     '.content.active .js-Message button.js-submit',
    )

    modal_ready(browser: browser2)
    watch_for(
      browser: browser2,
      css:     '.modal',
      value:   "#{title_text} #3",
    )
    watch_for(
      browser: browser2,
      css:     '.modal',
      value:   "#{message_text} #3",
    )
    watch_for(
      browser: browser2,
      css:     '.modal',
      value:   'Continue session',
    )

    match_not(
      browser: browser1,
      css:     'body',
      value:   message_text,
    )
  end

end
