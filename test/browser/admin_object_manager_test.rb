# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'browser_test_helper'

class AdminObjectManagerTest < TestCase

  def test_basic_a

    @browser = browser_instance
    login(
      username: 'master@example.com',
      password: 'test',
      url:      browser_url,
    )
    tasks_close_all()

    # already existing
    object_manager_attribute_create(
      data:  {
        name:      'customer_id',
        display:   'Customer Should Not Creatable',
        data_type: 'Text',
      },
      error: 'already exists'
    )

    # invalid name
    object_manager_attribute_create(
      data:  {
        name:      'some_other_id',
        display:   'Should Not Creatable',
        data_type: 'Text',
      },
      error: 'are not allowed'
    )

    # invalid name
    object_manager_attribute_create(
      data:  {
        name:      'some_other_ids',
        display:   'Should Not Creatable',
        data_type: 'Text',
      },
      error: 'are not allowed'
    )

    # invalid name
    object_manager_attribute_create(
      data:  {
        name:      'some spaces',
        display:   'Should Not Creatable',
        data_type: 'Text',
      },
      error: 'are not allowed'
    )

    # valid name
    object_manager_attribute_create(
      data: {
        name:      'browser_test1',
        display:   'Browser Test 1',
        data_type: 'Text',
      },
    )

    watch_for(
      css:   '.content.active',
      value: 'Database Update required',
    )
    click(css: '.content.active .tab-pane.active div.js-execute')
    watch_for(
      css:   '.modal',
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
    ticket_create(
      data:                {
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
      custom_data_input:   {
        browser_test1: 'some value öäüß',
      },
      disable_group_check: true,
    )

    # update ticket
    ticket_update(
      data:              {},
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
      css:   '.content.active table',
      value: 'browser_test1',
    )
    match_not(
      css:   '.content.active',
      value: 'Database Update required',
    )
    object_manager_attribute_delete(
      data: {
        name: 'browser_test1',
      },
    )
    watch_for(
      css:   '.content.active',
      value: 'Database Update required',
    )
    watch_for(
      css:   '.content.active table',
      value: 'browser_test1',
    )
    click(css: '.content.active .tab-pane.active div.js-execute')
    watch_for(
      css:   '.modal',
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
      css:   '.content.active',
      value: 'Database Update required',
    )
    match_not(
      css:   '.content.active table',
      value: 'browser_test1',
    )
  end

  def test_basic_b
    @browser = browser_instance
    login(
      username: 'master@example.com',
      password: 'test',
      url:      browser_url,
    )
    tasks_close_all()

    object_manager_attribute_create(
      data: {
        name:        'browser_test2',
        display:     'Browser Test 2',
        data_type:   'Select',
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
        name:      'browser_test2',
        display:   'Browser Test 2',
        data_type: 'Text',
        #data_option: {
        #  default: 'xxx',
        #},
      },
    )
    object_manager_attribute_create(
      data: {
        name:        'browser_test3',
        display:     'Browser Test 3',
        data_type:   'Select',
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
        name:      'browser_test4',
        display:   'Browser Test 4',
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
        name:      'browser_test5',
        display:   'Browser Test 5',
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
        name:      'browser_test6',
        display:   'Browser Test 6',
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
        name:        'browser_test7',
        display:     'Browser Test 7',
        data_type:   'Boolean',
        data_option: {
          options: {
            true:  'YES',
            false: 'NO',
          },
          #  default: true,
        },
      },
    )
    # rubocop:enable Lint/BooleanSymbol

    watch_for(
      css:   '.content.active',
      value: 'Database Update required',
    )
    click(css: '.content.active .tab-pane.active div.js-execute')
    watch_for(
      css:   '.modal',
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
    ticket_create(
      data:                {
        customer: 'nico',
        group:    'Users',
        priority: '2 normal',
        state:    'open',
        title:    'ticket attribute test all #1',
        body:     'ticket attribute test all #1',
      },
      custom_data_select:  {
        browser_test3: 'CC',
        browser_test7: 'NO',
      },
      custom_data_input:   {
        browser_test2: 'some value öäüß',
        browser_test4: '25',
      },
      disable_group_check: true,
    )

    ticket_verify(
      data: {
        title:              'ticket attribute test all #1',
        custom_data_select: {
          browser_test3: 'CC',
          browser_test7: 'NO',
        },
        custom_data_input:  {
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
    sleep 1
    object_manager_attribute_migrate

    match_not(
      css:   '.content.active',
      value: 'Database Update required',
    )
    match_not(
      css:   '.content.active table',
      value: 'browser_test2',
    )
    match_not(
      css:   '.content.active table',
      value: 'browser_test3',
    )
    match_not(
      css:   '.content.active table',
      value: 'browser_test4',
    )
    match_not(
      css:   '.content.active table',
      value: 'browser_test5',
    )
    match_not(
      css:   '.content.active table',
      value: 'browser_test6',
    )
    match_not(
      css:   '.content.active table',
      value: 'browser_test7',
    )
  end

  def test_basic_c
    @browser = browser_instance
    login(
      username: 'master@example.com',
      password: 'test',
      url:      browser_url,
    )
    tasks_close_all()

    # valid name
    object_manager_attribute_create(
      data: {
        name:      'browser_update_test1',
        display:   'Browser Update Test 1',
        data_type: 'Text',
      },
    )

    watch_for(
      css:   '.content.active',
      value: 'Database Update required',
    )
    click(css: '.content.active .tab-pane.active div.js-execute')
    watch_for(
      css:   '.modal',
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
      css:   '.content.active',
      value: 'Database Update required',
    )

    # valid name
    object_manager_attribute_update(
      data: {
        name:      'browser_update_test1',
        display:   'Browser Update Test 2',
        data_type: 'Text',
      },
    )

    watch_for(
      css:   '.content.active',
      value: 'Database Update required',
    )
    click(css: '.content.active .tab-pane.active div.js-execute')
    watch_for(
      css:   '.modal',
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
      css:   '.content.active',
      value: 'Database Update required',
    )

    object_manager_attribute_delete(
      data: {
        name: 'browser_update_test1',
      },
    )
    watch_for(
      css:   '.content.active',
      value: 'Database Update required',
    )
    watch_for(
      css:   '.content.active table',
      value: 'browser_update_test1',
    )
    click(css: '.content.active .tab-pane.active div.js-execute')
    watch_for(
      css:   '.modal',
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
      css:   '.content.active',
      value: 'Database Update required',
    )
    match_not(
      css:   '.content.active table',
      value: 'browser_update_test1',
    )

  end

  def test_that_attributes_with_references_should_have_a_disabled_delete_button
    @browser = instance = browser_instance
    login(
      username: 'master@example.com',
      password: 'test',
      url:      browser_url,
    )

    tasks_close_all()

    # create two new attributes
    object_manager_attribute_create(
      data: {
        name:      'deletable_attribute',
        display:   'Deletable Attribute',
        data_type: 'Text',
      },
    )

    object_manager_attribute_create(
      data: {
        name:      'undeletable_attribute',
        display:   'Undeletable Attribute',
        data_type: 'Text',
      },
    )

    watch_for(
      css:   '.content.active',
      value: 'Database Update required',
    )
    click(css: '.content.active .tab-pane.active div.js-execute')
    watch_for(
      css:   '.modal',
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
      css:   '.content.active',
      value: 'Database Update required',
    )

    # create a new overview that references the undeletable_attribute
    overview_create(
      browser: instance,
      data:    {
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
      browser:  instance,
      css:      'a[href="#manage"]',
      mute_log: true,
    )
    click(
      browser:  instance,
      css:      '.content.active a[href="#system/object_manager"]',
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

  def test_proper_sorting_of_select_attributes
    @browser = browser_instance
    login(
      username: 'master@example.com',
      password: 'test',
      url:      browser_url,
    )
    tasks_close_all()

    # lexicographically ordered list of option strings
    options = %w[0 000.000 1 100.100 100.200 2 200.100 200.200 3 ä b n ö p sr ß st t ü v]
    options_hash = options.reverse.collect { |o| [o, o] }.to_h

    object_manager_attribute_create(
      data: {
        name:        'select_attributes_sorting_test',
        display:     'Select Attributes Sorting Test',
        data_type:   'Select',
        data_option: { options: options_hash },
      },
    )
    sleep 2

    # open the select attribute that we just created
    execute(js: "$(\".content.active td:contains('select_attributes_sorting_test')\").first().click()")
    sleep 3

    unsorted_locations = options.map do |key|
      [get_location(xpath: "//input[@value='#{key}']").y, key]
    end
    log("unsorted_locations = #{unsorted_locations.inspect}")
    sorted_locations = unsorted_locations.sort_by(&:first).map(&:second)
    log("sorted_locations = #{sorted_locations.inspect}")
    assert_equal options, sorted_locations

    # close the attribute modal
    click(css: '.modal button.js-submit')

    watch_for(
      css:   '.content.active',
      value: 'Database Update required',
    )
    watch_for(
      css:   '.content.active table',
      value: 'select_attributes_sorting_test',
    )

    click(css: '.content.active .tab-pane.active div.js-execute')
    watch_for(
      css:   '.modal',
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

    # create a new ticket and check whether the select attributes are correctly sorted or not
    click(
      css:      'a[href="#ticket/create"]',
      mute_log: true,
    )

    watch_for(
      css: 'select[name="select_attributes_sorting_test"]',
    )

    select_element = @browser.find_elements(css: 'select[name="select_attributes_sorting_test"]')[0]
    unsorted_options = select_element.find_elements(xpath: './*').map(&:text).reject { |x| x == '-' }
    log unsorted_options.inspect
    assert_equal options, unsorted_options

    object_manager_attribute_delete(
      data: {
        name: 'select_attributes_sorting_test',
      },
    )
    object_manager_attribute_migrate
  end

  def test_deleted_select_attributes
    @browser = browser_instance
    login(
      username: 'master@example.com',
      password: 'test',
      url:      browser_url,
    )

    options = %w[äöü cat delete dog ß].map { |x| [x, "#{x.capitalize} Display"] }.to_h
    options_no_dog = options.except('dog')
    options_no_dog_no_delete = options_no_dog.except('delete')

    tasks_close_all()

    object_manager_attribute_create(
      data: {
        name:        'select_attributes_delete_test',
        display:     'Select Attributes Delete Test',
        data_type:   'Select',
        data_option: {
          options: options,
        },
      },
    )
    object_manager_attribute_migrate

    ticket_create(
      data:                {
        customer: 'nico',
        group:    'Users',
        title:    'select_attributes_delete_test',
        body:     'select_attributes_delete_test',
      },
      custom_data_select:  {
        select_attributes_delete_test: 'Delete Display',
      },
      disable_group_check: true,
    )

    watch_for(
      css: '.content.active select[name="select_attributes_delete_test"]',
    )

    # confirm that all options and their display values are there and are in the correct order
    select_element = @browser.find_elements(css: '.content.active select[name="select_attributes_delete_test"]')[0]
    unsorted_options = select_element.find_elements(xpath: './*').map { |o| o.attribute('value') }.reject { |x| x == '' }
    assert_equal options.keys, unsorted_options
    unsorted_display_options = select_element.find_elements(xpath: './*').map(&:text).reject { |x| x == '-' }
    assert_equal options.values, unsorted_display_options

    # confirm that the "delete" option is selected and that its display text is indeed "Delete Display"
    selected_option = select_element.find_elements(css: 'option:checked')[0]
    assert_equal 'delete', selected_option.attribute('value')
    assert_equal 'Delete Display', selected_option.text

    object_manager_attribute_update(
      data: {
        name:        'select_attributes_delete_test',
        data_option: {
          options: options_no_dog_no_delete,
        },
      },
    )
    object_manager_attribute_migrate

    screenshot(comment: 'deleted_select_attributes_before_click')

    # open the previously created ticket and verify its attribute selection
    click(
      xpath: '//a/div[contains(text(),"select_attributes_delete_test")]',
    )
    # confirm that all options and their display values are there and are in the correct order
    select_element = @browser.find_elements(css: '.content.active select[name="select_attributes_delete_test"]')[0]
    unsorted_options = select_element.find_elements(xpath: './*').map { |o| o.attribute('value') }.reject { |x| x == '' }
    assert_equal options_no_dog.keys, unsorted_options
    unsorted_display_options = select_element.find_elements(xpath: './*').map(&:text).reject { |x| x == '-' }
    assert_equal options_no_dog.values, unsorted_display_options

    # confirm that the "delete" option is still selected and that its display text is still indeed "Delete Display"
    selected_option = select_element.find_elements(css: 'option:checked')[0]
    assert_equal 'delete', selected_option.attribute('value')
    assert_equal 'Delete Display', selected_option.text

    # create a new ticket and check that the deleted options no longer appear
    click(
      css:      'a[href="#ticket/create"]',
      mute_log: true,
    )

    watch_for(
      css: 'select[name="select_attributes_delete_test"]',
    )

    select_element = @browser.find_elements(css: 'select[name="select_attributes_delete_test"]')[0]
    unsorted_options = select_element.find_elements(xpath: './*').map { |o| o.attribute('value') }.reject { |x| x == '' }
    assert_equal options_no_dog_no_delete.keys, unsorted_options
    unsorted_display_options = select_element.find_elements(xpath: './*').map(&:text).reject { |x| x == '-' }
    assert_equal options_no_dog_no_delete.values, unsorted_display_options

    object_manager_attribute_delete(
      data: {
        name: 'select_attributes_delete_test',
      },
    )
    object_manager_attribute_migrate
  end

  # verify fix for issue #2233 - Boolean object set to false is not visible
  # verify fix for issue #2277 - Note is not shown for customer / organisations if it's empty
  def test_false_boolean_attributes_gets_displayed_for_organizations
    @browser = browser_instance
    login(
      username: 'master@example.com',
      password: 'test',
      url:      browser_url,
    )
    tasks_close_all()

    object_manager_attribute_create(
      data: {
        object:      'Organization',
        name:        'bool_test',
        display:     'bool_test',
        data_type:   'Boolean',
        data_option: {
          options: {
            # rubocop:disable Lint/BooleanSymbol
            true:  'YES',
            false: 'NO',
            # rubocop:enable Lint/BooleanSymbol
          }
        },
      },
    )
    object_manager_attribute_create(
      data: {
        object:    'Organization',
        name:      'text_test',
        display:   'text_test',
        data_type: 'Text',
      },
    )
    object_manager_attribute_migrate

    ticket_open_by_title(title: 'select')

    click( css: '.content.active .tabsSidebar-tab[data-tab="organization"]' )
    click( css: '.content.active .sidebar[data-tab="organization"] .js-actions .dropdown-toggle' )
    click( css: '.content.active .sidebar[data-tab="organization"] .js-actions [data-type="organization-edit"]' )

    modal_ready
    select(css: '.content.active .modal select[name="bool_test"]', value: 'NO')
    click( css: '.content.active .modal .js-submit' )
    modal_disappear

    watch_for(
      css:   '.content.active .sidebar[data-tab="organization"] .sidebar-content',
      value: 'bool_test',
    )
    match_not(
      css:   '.content.active .sidebar[data-tab="organization"] .sidebar-content',
      value: 'text_test',
    )
    match(
      css:   '.content.active .sidebar[data-tab="organization"] .sidebar-content',
      value: 'note',
    )

    object_manager_attribute_delete(
      data: {
        object: 'Organization',
        name:   'bool_test',
      },
    )
    object_manager_attribute_delete(
      data: {
        object: 'Organization',
        name:   'text_test',
      },
    )
    object_manager_attribute_migrate
  end

  # verify fix for issue #2233 - Boolean object set to false is not visible
  # verify fix for issue #2277 - Note is not shown for customer / organisations if it's empty
  def test_false_boolean_attributes_gets_displayed_for_users
    @browser = browser_instance
    login(
      username: 'master@example.com',
      password: 'test',
      url:      browser_url,
    )
    tasks_close_all()

    object_manager_attribute_create(
      data: {
        object:      'User',
        name:        'bool_test',
        display:     'bool_test',
        data_type:   'Boolean',
        data_option: {
          options: {
            # rubocop:disable Lint/BooleanSymbol
            true:  'YES',
            false: 'NO',
            # rubocop:enable Lint/BooleanSymbol
          }
        },
      },
    )
    object_manager_attribute_create(
      data: {
        object:    'User',
        name:      'text_test',
        display:   'text_test',
        data_type: 'Text',
      },
    )
    object_manager_attribute_migrate

    ticket_open_by_title(title: 'select')

    click( css: '.content.active .tabsSidebar-tab[data-tab="customer"]' )
    click( css: '.content.active .sidebar[data-tab="customer"] .js-actions .dropdown-toggle' )
    click( css: '.content.active .sidebar[data-tab="customer"] .js-actions [data-type="customer-edit"]' )

    modal_ready
    select(css: '.content.active .modal select[name="bool_test"]', value: 'NO')
    click( css: '.content.active .modal .js-submit' )
    modal_disappear

    watch_for(
      css:   '.content.active .sidebar[data-tab="customer"] .sidebar-content',
      value: 'bool_test',
    )
    match_not(
      css:   '.content.active .sidebar[data-tab="customer"] .sidebar-content',
      value: 'text_test',
    )
    match(
      css:   '.content.active .sidebar[data-tab="customer"] .sidebar-content',
      value: 'note',
    )

    object_manager_attribute_delete(
      data: {
        object: 'User',
        name:   'bool_test',
      },
    )
    object_manager_attribute_delete(
      data: {
        object: 'User',
        name:   'text_test',
      },
    )
    object_manager_attribute_migrate
  end
end
