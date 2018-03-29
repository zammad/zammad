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

    correct_options = [
      {
        'name'     => 'Incident',
        'value'    => 'Incident',
        'children' => [
          {
            'name'     => 'Hardware',
            'value'    => 'Incident::Hardware',
            'children' => [
              {
                'name'  => 'Monitor',
                'value' => 'Incident::Hardware::Monitor'
              },
              {
                'name'  => 'Mouse',
                'value' => 'Incident::Hardware::Mouse'
              },
              {
                'name'  => 'Keyboard',
                'value' => 'Incident::Hardware::Keyboard'
              }
            ]
          },
          {
            'name'     => 'Softwareproblem',
            'value'    => 'Incident::Softwareproblem',
            'children' => [
              {
                'name'  => 'CRM',
                'value' => 'Incident::Softwareproblem::CRM'
              },
              {
                'name' => 'EDI',
                'value' => 'Incident::Softwareproblem::EDI'
              },
              {
                'name'     => 'SAP',
                'value'    => 'Incident::Softwareproblem::SAP',
                'children' => [
                  {
                    'name'  => 'Authentication',
                    'value' => 'Incident::Softwareproblem::SAP::Authentication'
                  },
                  {
                    'name'  => 'Not reachable',
                    'value' => 'Incident::Softwareproblem::SAP::Not reachable'
                  }
                ]
              },
              {
                'name'     => 'MS Office',
                'value'    => 'Incident::Softwareproblem::MS Office',
                'children' => [
                  {
                    'name'  => 'Excel',
                    'value' => 'Incident::Softwareproblem::MS Office::Excel'
                  },
                  {
                    'name'  => 'PowerPoint',
                    'value' => 'Incident::Softwareproblem::MS Office::PowerPoint'
                  },
                  {
                    'name'  => 'Word',
                    'value' => 'Incident::Softwareproblem::MS Office::Word'
                  },
                  {
                    'name'  => 'Outlook',
                    'value' => 'Incident::Softwareproblem::MS Office::Outlook'
                  }
                ]
              }
            ]
          }
        ]
      },
      {
        'name'     => 'Service request',
        'value'    => 'Service request',
        'children' => [
          {
            'name'  => 'New software requirement',
            'value' => 'Service request::New software requirement'
          },
          {
            'name'  => 'New hardware',
            'value' => 'Service request::New hardware'
          },
          {
            'name'  => 'Consulting',
            'value' => 'Service request::Consulting'
          }
        ]
      },
      {
        'name'  => 'Change request',
        'value' => 'Change request'
      }
    ]

    created_attribute = ObjectManager::Attribute.last
    assert_equal(correct_options, created_attribute.data_option[:options])

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
      timeout: 120,
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
      timeout: 120,
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
