require 'browser_test_helper'

class AdminObjectManagerTreeSelectTest < TestCase

  def test_basic_a

    @browser = browser_instance
    login(
      username: 'master@example.com',
      password: 'test',
      url: browser_url,
    )
    tasks_close_all()

    object_manager_attribute_create(
      data: {
        name:      'browser_test_tree_select1',
        display:   'Browser Test TreeSelect1',
        data_type: 'Tree Select',
        data_option: {
          options: {
            'Incident' => {
              'Hardware' => {
                'Monitor'  => {},
                'Mouse'    => {},
                'Keyboard' => {},
              },
              'Softwareproblem' => {
                'CRM' => {},
                'EDI' => {},
                'SAP' => {
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
            'Change request' => {},
          },
        },
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
      css: '.content.active table',
      value: 'browser_test_tree_select1',
    )
    match_not(
      css: '.content.active',
      value: 'Database Update required',
    )
    object_manager_attribute_delete(
      data: {
        name: 'browser_test_tree_select1',
      },
    )
    watch_for(
      css: '.content.active',
      value: 'Database Update required',
    )
    watch_for(
      css: '.content.active table',
      value: 'browser_test_tree_select1',
    )
    click(css: '.content.active .tab-pane.active div.js-execute')
    watch_for(
      css: '.modal',
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
      css: '.content.active',
      value: 'Database Update required',
    )
    match_not(
      css: '.content.active table',
      value: 'browser_test_tree_select1',
    )
  end

end
