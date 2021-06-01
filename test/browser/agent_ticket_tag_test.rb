# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'browser_test_helper'

class AgentTicketTagTest < TestCase
  def test_a_tags
    @browser = browser_instance
    login(
      username: 'agent1@example.com',
      password: 'test',
      url:      browser_url,
    )
    tasks_close_all()

    # set tag (by tab)
    ticket_create(
      data:          {
        customer: 'nico',
        group:    'Users',
        title:    'some subject 123äöü - tags 1',
        body:     'some body 123äöü - tags 1',
      },
      do_not_submit: true,
    )
    sleep 1
    set(
      css:   '.active .ticket-form-bottom .token-input',
      value: 'tag1, tag2',
    )
    sendkey(value: :tab)

    # reload browser
    sleep 6
    reload()
    sleep 2

    click(
      css: '.active .newTicket button.js-submit',
    )
    sleep 5
    if !@browser.current_url.match?(%r{#{Regexp.quote('#ticket/zoom/')}})
      raise 'Unable to create ticket!'
    end

    # verify tags
    tags_verify(
      tags: {
        'tag1' => true,
        'tag2' => true,
        'tag3' => false,
        'tag4' => false,
      }
    )

    # set tag (by blur)
    ticket_create(
      data:          {
        customer: 'nico',
        group:    'Users',
        title:    'some subject 123äöü - tags 2',
        body:     'some body 123äöü - tags 2',
      },
      do_not_submit: true,
    )
    sleep 1
    set(
      css:   '.active .ticket-form-bottom .token-input',
      value: 'tag3, tag4',
    )
    click(css: '#global-search')
    click(css: '.active .newTicket button.js-submit')
    sleep 5
    if !@browser.current_url.match?(%r{#{Regexp.quote('#ticket/zoom/')}})
      raise 'Unable to create ticket!'
    end

    # verify tags
    tags_verify(
      tags: {
        'tag1' => false,
        'tag2' => false,
        'tag3' => true,
        'tag4' => true,
      }
    )

    ticket3 = ticket_create(
      data: {
        customer: 'nico',
        group:    'Users',
        title:    'some subject 123äöü - tags 3',
        body:     'some body 123äöü - tags 3',
      },
    )

    # verify changes in second browser
    browser2 = browser_instance
    login(
      browser:  browser2,
      username: 'master@example.com',
      password: 'test',
      url:      browser_url,
    )
    ticket_open_by_search(
      browser: browser2,
      number:  ticket3[:number],
    )
    empty_search(
      browser: browser2,
    )

    # set tag #1
    click(
      css: '.content.active .js-newTagLabel',
    )
    set(
      css:   '.content.active .js-newTagInput',
      value: 'tag1',
    )
    sleep 2
    sendkey(
      value: :enter,
    )
    sleep 10

    # set tag #2
    click(
      css: '.content.active .js-newTagLabel',
    )
    set(
      css:   '.content.active .js-newTagInput',
      value: 'tag 2',
    )
    sendkey(
      value: :enter,
    )
    sleep 10

    # set tag #3 + #4
    click(
      css: '.content.active .js-newTagLabel',
    )
    set(
      css:   '.content.active .js-newTagInput',
      value: 'tag3, tag4',
    )
    sendkey(
      value: :enter,
    )
    sleep 10

    # set tag #5
    click(
      css: '.content.active .js-newTagLabel',
    )
    set(
      css:   '.content.active .js-newTagInput',
      value: 'tag5',
    )
    click(
      css: '#global-search',
    )
    sleep 10

    # verify tags
    tags_verify(
      tags: {
        'tag1'  => true,
        'tag 2' => true,
        'tag2'  => false,
        'tag3'  => true,
        'tag4'  => true,
        'tag5'  => true,
      }
    )

    sleep 4
    tags_verify(
      browser: browser2,
      tags:    {
        'tag1'  => true,
        'tag 2' => true,
        'tag2'  => false,
        'tag3'  => true,
        'tag4'  => true,
        'tag5'  => true,
      }
    )

    # reload browser
    reload()
    sleep 2

    # verify tags
    tags_verify(
      tags: {
        'tag1'  => true,
        'tag 2' => true,
        'tag2'  => false,
        'tag3'  => true,
        'tag4'  => true,
        'tag5'  => true,
      }
    )

    tags_verify(
      browser: browser2,
      tags:    {
        'tag1'  => true,
        'tag 2' => true,
        'tag2'  => false,
        'tag3'  => true,
        'tag4'  => true,
        'tag5'  => true,
      }
    )

    # remove tag1
    click(
      css: '.content.active .tags .js-delete',
    )
    sleep 4

    # verify tags
    tags_verify(
      tags: {
        'tag1'  => false,
        'tag 2' => true,
        'tag2'  => false,
        'tag3'  => true,
        'tag4'  => true,
        'tag5'  => true,
      }
    )
    tags_verify(
      browser: browser2,
      tags:    {
        'tag1'  => false,
        'tag 2' => true,
        'tag2'  => false,
        'tag3'  => true,
        'tag4'  => true,
        'tag5'  => true,
      }
    )

    # verify changes via admin interface
    click(
      browser: browser2,
      css:     'a[href="#manage"]',
    )
    click(
      browser: browser2,
      css:     '.content.active a[href="#manage/tags"]',
    )
    sleep 3
    execute(
      browser: browser2,
      js:      "$('.content.active .js-name:contains(\"tag3\")').click()",
    )

    modal_ready(
      browser: browser2,
    )

    set(
      browser: browser2,
      css:     '.modal [name="name"]',
      value:   'TAGXX',
    )
    click(
      browser: browser2,
      css:     '.modal .js-submit',
    )
    modal_disappear(browser: browser2)
    ticket_open_by_search(
      browser: browser2,
      number:  ticket3[:number],
    )
    empty_search(
      browser: browser2,
    )

    # verify tags
    tags_verify(
      tags: {
        'tag1'  => false,
        'tag 2' => true,
        'tag2'  => false,
        'tag3'  => false,
        'tag4'  => true,
        'tag5'  => true,
        'TAGXX' => true,
      }
    )
    tags_verify(
      browser: browser2,
      tags:    {
        'tag1'  => false,
        'tag 2' => true,
        'tag2'  => false,
        'tag3'  => false,
        'tag4'  => true,
        'tag5'  => true,
        'TAGXX' => true,
      }
    )

    click(
      browser: browser2,
      css:     'a[href="#manage"]',
    )
    click(
      browser: browser2,
      css:     '.content.active a[href="#manage/tags"]',
    )
    sleep 3
    execute(
      browser: browser2,
      js:      "$('.content.active .js-name:contains(\"tag5\")').closest('tr').find('.js-delete').click()",
    )

    modal_ready(
      browser: browser2,
    )

    click(
      browser: browser2,
      css:     '.modal .js-submit',
    )
    modal_disappear(browser: browser2)
    ticket_open_by_search(
      browser: browser2,
      number:  ticket3[:number],
    )

    # verify tags
    tags_verify(
      tags: {
        'tag1'  => false,
        'tag 2' => true,
        'tag2'  => false,
        'tag3'  => false,
        'tag4'  => true,
        'tag5'  => false,
        'TAGXX' => true,
      }
    )
    tags_verify(
      browser: browser2,
      tags:    {
        'tag1'  => false,
        'tag 2' => true,
        'tag2'  => false,
        'tag3'  => false,
        'tag4'  => true,
        'tag5'  => false,
        'TAGXX' => true,
      }
    )
  end

  def test_b_tags
    tag_prefix = "tag#{rand(1000)}"

    @browser = browser_instance
    login(
      username: 'master@example.com',
      password: 'test',
      url:      browser_url,
    )
    tasks_close_all()

    click(css: 'a[href="#manage"]')
    click(css: '.content.active a[href="#manage/tags"]')
    switch(
      css:  '.content.active .js-newTagSetting',
      type: 'off',
    )

    set(
      css:   '.content.active .js-create input[name="name"]',
      value: "#{tag_prefix} A",
    )
    click(css: '.content.active .js-create .js-submit')
    set(
      css:   '.content.active .js-create input[name="name"]',
      value: "#{tag_prefix} a",
    )
    click(css: '.content.active .js-create .js-submit')
    set(
      css:   '.content.active .js-create input[name="name"]',
      value: "#{tag_prefix} B",
    )
    click(css: '.content.active .js-create .js-submit')
    set(
      css:   '.content.active .js-create input[name="name"]',
      value: "#{tag_prefix} C",
    )
    click(css: '.content.active .js-create .js-submit')

    # set tag (by tab)
    ticket_create(
      data:          {
        customer: 'nico',
        group:    'Users',
        title:    'some subject 123äöü - tags no new 1',
        body:     'some body 123äöü - tags no new 1',
      },
      do_not_submit: true,
    )
    sleep 1
    set(
      css:   '.active .ticket-form-bottom .token-input',
      value: "#{tag_prefix} A",
    )
    sleep 2
    sendkey(value: :tab)
    sleep 1
    set(
      css:   '.active .ticket-form-bottom .token-input',
      value: "#{tag_prefix} a",
    )
    sleep 2
    sendkey(value: :tab)
    sleep 1
    set(
      css:   '.active .ticket-form-bottom .token-input',
      value: "#{tag_prefix} B",
    )
    sleep 2
    sendkey(value: :tab)
    sleep 1
    set(
      css:   '.active .ticket-form-bottom .token-input',
      value: 'NOT EXISTING',
    )
    sleep 2
    sendkey(value: :tab)
    sleep 1

    click(
      css: '.active .newTicket button.js-submit',
    )
    sleep 5
    if !@browser.current_url.match?(%r{#{Regexp.quote('#ticket/zoom/')}})
      raise 'Unable to create ticket!'
    end

    # verify tags
    tags_verify(
      tags: {
        "#{tag_prefix} A" => true,
        "#{tag_prefix} a" => true,
        "#{tag_prefix} B" => true,
        'NOT EXISTING'    => false,
      }
    )

    # new ticket with tags in zoom
    ticket_create(
      data: {
        customer: 'nico',
        group:    'Users',
        title:    'some subject 123äöü - tags no new 2',
        body:     'some body 223äöü - tags no new 1',
      },
    )
    sleep 2

    click(css: '.active .sidebar .js-newTagLabel')
    set(
      css:   '.active .sidebar .js-newTagInput',
      value: "#{tag_prefix} A",
    )
    sleep 2
    sendkey(value: :tab)
    sleep 1
    click(css: '.active .sidebar .js-newTagLabel')
    set(
      css:   '.active .sidebar .js-newTagInput',
      value: "#{tag_prefix} a",
    )
    sleep 2
    sendkey(value: :tab)
    sleep 1
    click(css: '.active .sidebar .js-newTagLabel')
    set(
      css:   '.active .sidebar .js-newTagInput',
      value: "#{tag_prefix} B",
    )
    sleep 2
    sendkey(value: :tab)
    sleep 1
    click(css: '.active .sidebar .js-newTagLabel')
    set(
      css:   '.active .sidebar .js-newTagInput',
      value: 'NOT EXISTING',
    )
    sleep 2
    sendkey(value: :tab)
    sleep 1

    # verify tags
    tags_verify(
      tags: {
        "#{tag_prefix} A" => true,
        "#{tag_prefix} a" => true,
        "#{tag_prefix} B" => true,
        'NOT EXISTING'    => false,
      }
    )
    reload()
    sleep 2

    # verify tags
    tags_verify(
      tags: {
        "#{tag_prefix} A" => true,
        "#{tag_prefix} a" => true,
        "#{tag_prefix} B" => true,
        'NOT EXISTING'    => false,
      }
    )

    click(css: 'a[href="#manage"]')
    click(css: '.content.active a[href="#manage/tags"]')
    switch(
      css:  '.content.active .js-newTagSetting',
      type: 'on',
    )
  end
end
