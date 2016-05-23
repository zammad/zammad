# encoding: utf-8
require 'browser_test_helper'

class AdminObjectManagerTest < TestCase
  def test_basic
    name = "some overview #{rand(99_999_999)}"

    @browser = browser_instance
    login(
      username: 'master@example.com',
      password: 'test',
      url: browser_url,
    )
    tasks_close_all()

    click(css: 'a[href="#manage"]')
    click(css: 'a[href="#system/object_manager"]')

    click(css: '#content .js-new')

    modal_ready()

    # already existing
    set(
      css: '.modal input[name="name"]',
      value: 'customer_id',
    )
    set(
      css: '.modal input[name="display"]',
      value: 'Customer Should Not Creatable',
    )
    click(css: '.modal button.js-submit')
    sleep 4
    watch_for(
      css: '.modal',
      value: '(already exists)',
    )

    # invalid name
    set(
      css: '.modal input[name="name"]',
      value: 'some_other_id',
    )
    set(
      css: '.modal input[name="display"]',
      value: 'Should Not Creatable',
    )
    click(css: '.modal button.js-submit')
    sleep 4
    watch_for(
      css: '.modal',
      value: '(are not allowed)',
    )

    # invalid name
    set(
      css: '.modal input[name="name"]',
      value: 'some_other_ids',
    )
    set(
      css: '.modal input[name="display"]',
      value: 'Should Not Creatable',
    )
    click(css: '.modal button.js-submit')
    sleep 4
    watch_for(
      css: '.modal',
      value: '(are not allowed)',
    )

    # invalid name
    set(
      css: '.modal input[name="name"]',
      value: 'some spaces',
    )
    set(
      css: '.modal input[name="display"]',
      value: 'Should Not Creatable',
    )
    click(css: '.modal button.js-submit')
    sleep 4
    watch_for(
      css: '.modal',
      value: '(are not allowed)',
    )
    click(css: '.modal .js-close')
    modal_ready()

    # valid name
    click(css: '#content .js-new')
    modal_ready()
    set(
      css: '.modal input[name="name"]',
      value: 'browser_test1',
    )
    set(
      css: '.modal input[name="display"]',
      value: 'Browser Test 1',
    )
    click(css: '.modal button.js-submit')
    watch_for(
      css: '#content table',
      value: 'browser_test1',
    )
    watch_for(
      css: '#content',
      value: 'Database Update required',
    )
    click(css: '#content .tab-pane.active div.js-execute')
    watch_for(
      css: '.modal',
      value: 'New Version',
    )
    click(css: '.modal button.js-submit')

    # create new ticket

    # update ticket

    # discard new attribute

    watch_for(
      css: '#content table',
      value: 'browser_test1',
    )
    match_not(
      css: '#content',
      value: 'Database Update required',
    )
    click(css: '#content .tab-pane.active table tbody tr:last-child .js-delete')
    sleep 4
    watch_for(
      css: '#content',
      value: 'Database Update required',
    )
    watch_for(
      css: '#content table',
      value: 'browser_test1',
    )
    click(css: '#content .tab-pane.active div.js-execute')
    watch_for(
      css: '.modal',
      value: 'New Version',
    )
    click(css: '.modal button.js-submit')
    sleep 5
    match_not(
      css: '#content',
      value: 'Database Update required',
    )
    match_not(
      css: '#content table',
      value: 'browser_test1',
    )
  end

end
