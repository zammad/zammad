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
      css: '.content.active',
      value: 'Database Update required',
    )
    click(css: '.content.active .tab-pane.active div.js-execute')
    watch_for(
      css: '.modal',
      value: 'restart',
    )
    watch_for_disappear(
      css:     '.modal',
      timeout: 7.minutes,
    )
    sleep 5
    watch_for(
      css: '.content.active',
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
      css: '.content.active table',
      value: 'browser_test1',
    )
    match_not(
      css: '.content.active',
      value: 'Database Update required',
    )
    object_manager_attribute_delete(
      data: {
        name: 'browser_test1',
      },
    )
    watch_for(
      css: '.content.active',
      value: 'Database Update required',
    )
    watch_for(
      css: '.content.active table',
      value: 'browser_test1',
    )
    click(css: '.content.active .tab-pane.active div.js-execute')
    watch_for(
      css: '.modal',
      value: 'restart',
    )
    watch_for_disappear(
      css:     '.modal',
      timeout: 7.minutes,
    )
    sleep 5
    watch_for(
      css: '.content.active',
    )
    match_not(
      css: '.content.active',
      value: 'Database Update required',
    )
    match_not(
      css: '.content.active table',
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

    object_manager_attribute_discard_changes

    sleep 4

    object_manager_attribute_create(
      data: {
        name: 'browser_test2',
        display: 'Browser Test 2',
        data_type: 'Text',
        #data_option: {
        #  default: 'xxx',
        #},
      },
    )
    object_manager_attribute_create(
      data: {
        name: 'browser_test3',
        display: 'Browser Test 3',
        data_type: 'Select',
        data_option: {
          options: {
            'aa' => 'AA',
            'bb' => 'BB',
            'cc' => 'CC',
          },
        },
      },
    )

    object_manager_attribute_create(
      data: {
        name: 'browser_test4',
        display: 'Browser Test 4',
        data_type: 'Integer',
        #data_option: {
        #  default: 'xxx',
        #  min: 15,
        #  max: 99,
        #},
      },
    )

    object_manager_attribute_create(
      data: {
        name: 'browser_test5',
        display: 'Browser Test 5',
        data_type: 'Datetime',
        #data_option: {
        #  future: true,
        #  past: true,
        #  diff: 24
        #},
      },
    )

    object_manager_attribute_create(
      data: {
        name: 'browser_test6',
        display: 'Browser Test 6',
        data_type: 'Date',
        #data_option: {
        #  future: true,
        #  past: true,
        #  diff: 24
        #},
      },
    )

    # rubocop:disable Lint/BooleanSymbol
    object_manager_attribute_create(
      data: {
        name: 'browser_test7',
        display: 'Browser Test 7',
        data_type: 'Boolean',
        data_option: {
          options: {
            true: 'YES',
            false: 'NO',
          },
          #  default: true,
        },
      },
    )
    # rubocop:enable Lint/BooleanSymbol

    watch_for(
      css: '.content.active',
      value: 'Database Update required',
    )
    click(css: '.content.active .tab-pane.active div.js-execute')
    watch_for(
      css: '.modal',
      value: 'restart',
    )
    watch_for_disappear(
      css:     '.modal',
      timeout: 7.minutes,
    )
    sleep 5
    watch_for(
      css: '.content.active',
    )

    # create new ticket
    ticket = ticket_create(
      data: {
        customer: 'nico',
        group:    'Users',
        priority: '2 normal',
        state:    'open',
        title:    'ticket attribute test all #1',
        body:     'ticket attribute test all #1',
      },
      custom_data_select: {
        browser_test3: 'CC',
        browser_test7: 'NO',
      },
      custom_data_input: {
        browser_test2: 'some value öäüß',
        browser_test4: '25',
      },
      disable_group_check: true,
    )

    ticket_verify(
      data: {
        title: 'ticket attribute test all #1',
        custom_data_select: {
          browser_test3: 'CC',
          browser_test7: 'NO',
        },
        custom_data_input: {
          browser_test2: 'some value öäüß',
          browser_test4: '25',
        },
      },
    )

    object_manager_attribute_delete(
      data: {
        name: 'browser_test2',
      },
    )
    object_manager_attribute_delete(
      data: {
        name: 'browser_test3',
      },
    )
    object_manager_attribute_delete(
      data: {
        name: 'browser_test4',
      },
    )
    object_manager_attribute_delete(
      data: {
        name: 'browser_test5',
      },
    )
    object_manager_attribute_delete(
      data: {
        name: 'browser_test6',
      },
    )
    object_manager_attribute_delete(
      data: {
        name: 'browser_test7',
      },
    )
    click(css: '.content.active .tab-pane.active div.js-execute')
    watch_for(
      css: '.modal',
      value: 'restart',
    )
    watch_for_disappear(
      css:     '.modal',
      timeout: 7.minutes,
    )
    sleep 5
    watch_for(
      css: '.content.active',
    )
    match_not(
      css: '.content.active',
      value: 'Database Update required',
    )
    match_not(
      css: '.content.active table',
      value: 'browser_test2',
    )
    match_not(
      css: '.content.active table',
      value: 'browser_test3',
    )
    match_not(
      css: '.content.active table',
      value: 'browser_test4',
    )
    match_not(
      css: '.content.active table',
      value: 'browser_test5',
    )
    match_not(
      css: '.content.active table',
      value: 'browser_test6',
    )
    match_not(
      css: '.content.active table',
      value: 'browser_test7',
    )
  end

  def test_basic_c
    @browser = browser_instance
    login(
      username: 'master@example.com',
      password: 'test',
      url: browser_url,
    )
    tasks_close_all()

    # valid name
    object_manager_attribute_create(
      data: {
        name: 'browser_update_test1',
        display: 'Browser Update Test 1',
        data_type: 'Text',
      },
    )

    watch_for(
      css: '.content.active',
      value: 'Database Update required',
    )
    click(css: '.content.active .tab-pane.active div.js-execute')
    watch_for(
      css: '.modal',
      value: 'restart',
    )
    watch_for_disappear(
      css:     '.modal',
      timeout: 7.minutes,
    )
    sleep 5
    watch_for(
      css: '.content.active',
    )
    match_not(
      css: '.content.active',
      value: 'Database Update required',
    )

    # valid name
    object_manager_attribute_update(
      data: {
        name: 'browser_update_test1',
        display: 'Browser Update Test 2',
        data_type: 'Text',
      },
    )

    watch_for(
      css: '.content.active',
      value: 'Database Update required',
    )
    click(css: '.content.active .tab-pane.active div.js-execute')
    watch_for(
      css: '.modal',
      value: 'configuration of Zammad has changed',
    )
    click(css: '.modal .js-submit')
    watch_for_disappear(
      css:     '.modal',
      timeout: 7.minutes,
    )
    sleep 5
    watch_for(
      css: '.content.active',
    )
    match_not(
      css: '.content.active',
      value: 'Database Update required',
    )

    object_manager_attribute_delete(
      data: {
        name: 'browser_update_test1',
      },
    )
    watch_for(
      css: '.content.active',
      value: 'Database Update required',
    )
    watch_for(
      css: '.content.active table',
      value: 'browser_update_test1',
    )
    click(css: '.content.active .tab-pane.active div.js-execute')
    watch_for(
      css: '.modal',
      value: 'restart',
    )
    watch_for_disappear(
      css:     '.modal',
      timeout: 7.minutes,
    )
    sleep 5
    watch_for(
      css: '.content.active',
    )
    match_not(
      css: '.content.active',
      value: 'Database Update required',
    )
    match_not(
      css: '.content.active table',
      value: 'browser_update_test1',
    )

  end

  def test_that_attributes_with_references_should_have_a_disabled_delete_button
    @browser = instance = browser_instance
    login(
      username: 'master@example.com',
      password: 'test',
      url: browser_url,
    )

    tasks_close_all()

    # create two new attributes
    object_manager_attribute_create(
      data: {
        name: 'deletable_attribute',
        display: 'Deletable Attribute',
        data_type: 'Text',
      },
    )

    object_manager_attribute_create(
      data: {
        name: 'undeletable_attribute',
        display: 'Undeletable Attribute',
        data_type: 'Text',
      },
    )

    watch_for(
      css: '.content.active',
      value: 'Database Update required',
    )
    click(css: '.content.active .tab-pane.active div.js-execute')
    watch_for(
      css: '.modal',
      value: 'restart',
    )
    watch_for_disappear(
      css:     '.modal',
      timeout: 7.minutes,
    )
    sleep 5
    watch_for(
      css: '.content.active',
    )
    match_not(
      css: '.content.active',
      value: 'Database Update required',
    )

    # create a new overview that references the undeletable_attribute
    overview_create(
      browser: instance,
      data: {
        name: 'test_overview',
        roles: ['Agent'],
        selector: {
          'Undeletable Attribute' => 'DUMMY',
        },
        'order::direction' => 'down',
        'text_input' => true,
      }
    )
    click(
      browser: instance,
      css:  'a[href="#manage"]',
      mute_log: true,
    )
    click(
      browser: instance,
      css:  '.content.active a[href="#system/object_manager"]',
      mute_log: true,
    )

    30.times do
      deletable_attribute = instance.find_elements(xpath: '//td[text()="deletable_attribute"]/following-sibling::*[2]')[0]
      break if deletable_attribute
      sleep 1
    end

    sleep 1
    deletable_attribute = instance.find_elements(xpath: '//td[text()="deletable_attribute"]/following-sibling::*[2]')[0]
    assert_not_nil(deletable_attribute)
    deletable_attribute_html = deletable_attribute.attribute('innerHTML')
    assert(deletable_attribute_html.include?('title="Delete"'))
    assert(deletable_attribute_html.include?('href="#"'))
    assert(deletable_attribute_html.exclude?('cannot be deleted'))

    undeletable_attribute = instance.find_elements(xpath: '//td[text()="undeletable_attribute"]/following-sibling::*[2]')[0]
    assert_not_nil(undeletable_attribute)
    undeletable_attribute_html = undeletable_attribute.attribute('innerHTML')
    assert(undeletable_attribute_html.include?('Overview'))
    assert(undeletable_attribute_html.include?('test_overview'))
    assert(undeletable_attribute_html.include?('cannot be deleted'))
    assert(undeletable_attribute_html.exclude?('href="#"'))
  end
end
