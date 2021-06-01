# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'browser_test_helper'

class AdminObjectManagerTreeSelectTest < TestCase

  def test_basic_a

    @browser = browser_instance
    login(
      username: 'master@example.com',
      password: 'test',
      url:      browser_url,
    )
    tasks_close_all()

    object_manager_attribute_create(
      data: {
        name:        'browser_test_tree_select1',
        display:     'Browser Test TreeSelect1',
        data_type:   'Tree Select',
        data_option: {
          options: {
            'Incident'        => {
              'Hardware'        => {
                'Monitor'  => {},
                'Mouse'    => {},
                'Keyboard' => {},
              },
              'Softwareproblem' => {
                'CRM'       => {},
                'EDI'       => {},
                'SAP'       => {
                  'Authentication' => {},
                  'Not reachable'  => {},
                },
                'MS Office' => {
                  'Excel'      => {},
                  'PowerPoint' => {},
                  'Word'       => {},
                  'Outlook'    => {},
                },
              },
            },
            'Service request' => {
              'New software requirement' => {},
              'New hardware'             => {},
              'Consulting'               => {},
            },
            'Change request'  => {},
          },
        },
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
      timeout: 240,
    )
    sleep 5
    watch_for(
      css: '.content.active',
    )

    # discard new attribute
    click(css: 'a[href="#manage"]')
    click(css: 'a[href="#system/object_manager"]')
    watch_for(
      css:   '.content.active table',
      value: 'browser_test_tree_select1',
    )
    match_not(
      css:   '.content.active',
      value: 'Database Update required',
    )
    object_manager_attribute_delete(
      data: {
        name: 'browser_test_tree_select1',
      },
    )
    watch_for(
      css:   '.content.active',
      value: 'Database Update required',
    )
    watch_for(
      css:   '.content.active table',
      value: 'browser_test_tree_select1',
    )
    click(css: '.content.active .tab-pane.active div.js-execute')
    watch_for(
      css:   '.modal',
      value: 'restart',
    )
    watch_for_disappear(
      css:     '.modal',
      timeout: 240,
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
      value: 'browser_test_tree_select1',
    )
  end

  # verify the fix for issue #2206 - Unable to modify tree_select attributes with fresh 2.6
  def test_modify_tree_select_attributes
    @browser = instance = browser_instance
    login(
      username: 'master@example.com',
      password: 'test',
      url:      browser_url,
    )
    tasks_close_all()

    object_manager_attribute_create(
      data: {
        name:        'browser_test_tree_select2',
        display:     'Browser Test TreeSelect2',
        data_type:   'Tree Select',
        data_option: {
          options: {
            'Incident'        => {
              'Hardware' => {
                'Monitor' => {},
                'Mouse'   => {},
              },
            },
            'Service request' => {
              'New software requirement' => {},
              'New hardware'             => {},
            },
            'Change request'  => {},
          },
        },
      },
    )
    object_manager_attribute_migrate

    # open the newly created tree_select and add some new options
    object_manager_attribute_update(
      data:          {
        name: 'browser_test_tree_select2',
      },
      do_not_submit: true,
    )

    # add two new first level entries
    2.times do |i|
      instance.find_elements(css: '.modal .js-treeTable .js-key').last.click

      element = instance.find_elements(css: '.modal .js-treeTable .js-key').last
      element.clear
      element.send_keys("new tree option #{i}")
    end

    click(
      css: '.modal button.js-submit'
    )
    modal_disappear

    object_manager_attribute_migrate

    # open the tree select again and check that the newly added options are there
    watch_for(
      css:   '.content.active table',
      value: 'browser_test_tree_select2',
    )
    object_manager_attribute_update(
      data:          {
        name: 'browser_test_tree_select2',
      },
      do_not_submit: true,
    )
    2.times do |i|
      exists(
        css:   '.modal .js-treeTable',
        value: "new tree option #{i}",
      )
    end
    modal_close

    # clean up and confirm the deletion of newly created attributes
    object_manager_attribute_delete(
      data: {
        name: 'browser_test_tree_select2',
      },
    )
    object_manager_attribute_migrate

    match_not(
      css:   '.content.active table',
      value: 'browser_test_tree_select2',
    )
  end
end
