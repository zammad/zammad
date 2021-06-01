# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'browser_test_helper'

class ManageTest < TestCase
  def test_user
    random     = "manage-test-#{rand(999_999)}"
    user_email = "#{random}@example.com"

    # user management
    @browser = browser_instance
    login(
      username: 'master@example.com',
      password: 'test',
      url:      browser_url,
    )

    click(css: 'a[href="#manage"]')
    click(css: 'a[href="#manage/users"]')

    user_create(
      data: {
        login:     "some login#{random}",
        firstname: "Manage Firstname#{random}",
        lastname:  "Manage Lastname#{random}",
        email:     user_email,
        password:  'some-pass',
      }
    )

    click(css: '.table-overview tr:last-child td')

    modal_ready()
    set(
      css:   '.modal input[name="lastname"]',
      value: "2Manage Lastname#{random}",
    )
    click(css: '.modal button.js-submit')
    modal_disappear()

    watch_for(
      css:   'body',
      value: "2Manage Lastname#{random}",
    )

    # sla
    sla_create(
      data: {
        name:                        "some sla#{random}",
        first_response_time_in_text: '1:01'
      }
    )
    watch_for(
      css:   'body',
      value: random,
    )
    sleep 1

    click(css: '.content:not(.hide) .action:last-child .js-edit')

    modal_ready()
    set(
      css:   '.modal input[name=name]',
      value: "some sla update #{random}",
    )
    set(
      css:   '.modal input[name="first_response_time_in_text"]',
      value: '2:01',
    )
    click(css: '.modal button.js-submit')
    modal_disappear()

    watch_for(
      css:   'body',
      value: "some sla update #{random}",
    )
    sleep 4

    click(css: '.content:not(.hide) .action:last-child .js-delete')
    sleep 2

    click(css: '.modal button.js-submit')
    sleep 4
    match_not(
      css:   'body',
      value: "some sla update #{random}",
    )

    click(css: 'a[href="#manage"]')
    click(css: 'a[href="#manage/slas"]')
    sleep 2
    match_not(
      css:   'body',
      value: "some sla update #{random}",
    )

    reload()
    sleep 2

    click(css: 'a[href="#manage"]')
    click(css: 'a[href="#manage/slas"]')
    sleep 2
    match_not(
      css:   'body',
      value: "some sla update #{random}",
    )
  end
end
