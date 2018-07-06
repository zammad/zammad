FactoryBot.define do
  sequence :object_manager_attribute_name do |n|
    "internal_name#{n}"
  end

  sequence :object_manager_attribute_display do |n|
    "Display Name #{n}"
  end
end

FactoryBot.define do
  factory :object_manager_attribute, class: ObjectManager::Attribute do

    object_lookup_id 2
    name    { generate(:object_manager_attribute_name) }
    display { generate(:object_manager_attribute_display) }
    data_option_new do
      {}
    end
    editable false
    active   true
    screens  do
      {
        'create_top' => {
          '-all-' => {
            'null' => false
          }
        },
        'edit' => {}
      }
    end
    add_attribute(:to_create) { false }
    to_migrate    false
    to_delete     false
    to_config     false
    position      15
    updated_by_id 1
    created_by_id 1
  end

  factory :object_manager_attribute_text, parent: :object_manager_attribute do
    data_type   'input'
    data_option do
      {
        'type'      => 'text',
        'maxlength' => 200,
        'null'      => true,
        'translate' => false,
        'default'   => '',
        'options'   => {},
        'relation'  => '',
      }
    end
  end

  factory :object_manager_attribute_select, parent: :object_manager_attribute do
    data_type   'select'
    data_option do
      {
        'default' => '',
        'options' => {
          'key_1' => 'value_1',
          'key_2' => 'value_2',
          'key_3' => 'value_3',
        },
        'relation' => '',
        'nulloption' => true,
        'multiple'   => false,
        'null'       => true,
        'translate'  => true,
        'maxlength'  => 255
      }
    end
  end

  factory :object_manager_attribute_tree_select, parent: :object_manager_attribute do
    data_type 'tree_select'
    data_option do
      {
        'options' => [
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
        ],
        'default'    => '',
        'null'       => true,
        'relation'   => '',
        'maxlength'  => 255,
        'nulloption' => true,
      }
    end
  end
end
