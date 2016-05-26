# encoding: utf-8
require 'browser_test_helper'

class AdminObjectManagerTest < TestCase
  def test_basic_a

    @browser = browser_instance
    login(
      username: 'master@example.com',
      password: 'test',
      url: browser_url,
    )
    tasks_close_all()

    # already existing
    object_manager_attribute_create(
      data: {
        name: 'customer_id',
        display: 'Customer Should Not Creatable',
        data_type: 'Text',
      },
      error: 'already exists'
    )

    # invalid name
    object_manager_attribute_create(
      data: {
        name: 'some_other_id',
        display: 'Should Not Creatable',
        data_type: 'Text',
      },
      error: 'are not allowed'
    )

    # invalid name
    object_manager_attribute_create(
      data: {
        name: 'some_other_ids',
        display: 'Should Not Creatable',
        data_type: 'Text',
      },
      error: 'are not allowed'
    )

    # invalid name
    object_manager_attribute_create(
      data: {
        name: 'some spaces',
        display: 'Should Not Creatable',
        data_type: 'Text',
      },
      error: 'are not allowed'
    )

    # valid name
    object_manager_attribute_create(
      data: {
        name: 'browser_test1',
        display: 'Browser Test 1',
        data_type: 'Text',
      },
    )

    watch_for(
      css: '#content',
      value: 'Database Update required',
    )
    click(css: '#content .tab-pane.active div.js-execute')
    watch_for(
      css: '.modal',
      value: 'restart',
    )
    watch_for_disappear(
      css:     '.modal',
      timeout: 26,
    )
    sleep 5
    watch_for(
      css: '#content',
    )

    # create new ticket
    ticket = ticket_create(
      data: {
        customer: 'nico',
        group:    'Users',
        priority: '2 normal',
        state:    'open',
        title:    'ticket attribute test #1',
        body:     'ticket attribute test #1',
      },
      #custom_data_select: {
      #  key1: 'some value',
      #},
      custom_data_input: {
        browser_test1: 'some value öäüß',
      },
      disable_group_check: true,
    )

    # update ticket
    ticket_update(
      data: {},
      #custom_data_select: {
      #  key1: 'some value',
      #},
      custom_data_input: {
        browser_test1: 'some value ABC',
      },
    )

    # discard new attribute
    click(css: 'a[href="#manage"]')
    click(css: 'a[href="#system/object_manager"]')
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
      value: 'restart',
    )
    watch_for_disappear(
      css:     '.modal',
      timeout: 26,
    )
    sleep 5
    watch_for(
      css: '#content',
    )
    match_not(
      css: '#content',
      value: 'Database Update required',
    )
    match_not(
      css: '#content table',
      value: 'browser_test1',
    )
  end

  def test_basic_b
    @browser = browser_instance
    login(
      username: 'master@example.com',
      password: 'test',
      url: browser_url,
    )
    tasks_close_all()

    object_manager_attribute_create(
      data: {
        name: 'browser_test2',
        display: 'Browser Test 2',
        data_type: 'Select',
        data_option: {
          options: {
            'aa' => 'AA',
            'bb' => 'BB',
          },
        },
      },
    )

    sleep 10

    object_manager_attribute_discard_changes

    #object_manager_attribute_delete(
    #  data: {
    #    name: 'browser_test2',
    #  },
    #)
  end

end
