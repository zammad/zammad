# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

FactoryBot.define do
  factory :object_manager_attribute, class: 'ObjectManager::Attribute' do
    transient do
      object_name { 'Ticket' }
      additional_data_options { nil }
      default { nil }
    end

    object_lookup_id          { ObjectLookup.by_name(object_name) }
    sequence(:name)           { |n| "internal_name#{n}" }
    sequence(:display)        { |n| "Display Name #{n}" }
    data_option_new           { {} }
    editable                  { true }
    active                    { true }
    add_attribute(:to_create) { true }
    to_migrate                { true }
    to_delete                 { false }
    to_config                 { false }
    position                  { 15 }
    updated_by_id             { 1 }
    created_by_id             { 1 }
    screens do
      {
        'create_top' => {
          '-all-' => {
            'null' => false
          }
        },
        'edit'       => {}
      }
    end

    callback(:after_stub, :before_create) do |object, context|
      next if context.additional_data_options.blank?

      object.data_option ||= {}
      object.data_option.merge! context.additional_data_options
    end

    trait :required_screen do
      screens do
        {
          'create_middle' =>
                             {
                               'ticket.customer'    => {
                                 shown:      true,
                                 required:   true,
                                 item_class: 'column'
                               },
                               'ticket.agent'       => {
                                 shown:      true,
                                 required:   true,
                                 item_class: 'column'
                               },
                               'admin.organization' => {
                                 shown:    true,
                                 required: true,
                               },
                               'admin.group'        => {
                                 shown:      true,
                                 required:   true,
                                 item_class: 'column'
                               },
                             },
          'edit'          =>
                             {
                               'ticket.customer'    => {
                                 shown:    true,
                                 required: true
                               },
                               'ticket.agent'       => {
                                 shown:    true,
                                 required: true
                               },
                               'admin.organization' => {
                                 shown:    true,
                                 required: true,
                               },
                               'admin.group'        => {
                                 shown:      true,
                                 required:   true,
                                 item_class: 'column'
                               },
                             }
        }
      end
    end

    trait :shown_screen do
      screens do
        {
          'create_middle' =>
                             {
                               '-all-' => {
                                 shown: true
                               }
                             },
          'edit'          =>
                             {
                               '-all-' => {
                                 shown: true
                               }
                             }
        }
      end
    end
  end

  factory :object_manager_attribute_text, parent: :object_manager_attribute do
    transient do
      data_option_maxlength { 200 }
    end

    default { '' }

    data_type { 'input' }
    data_option do
      {
        'type'      => 'text',
        'maxlength' => data_option_maxlength,
        'null'      => true,
        'translate' => false,
        'default'   => default,
        'options'   => {},
        'relation'  => '',
      }
    end
  end

  factory :object_manager_attribute_textarea, parent: :object_manager_attribute do
    default { '' }
    data_type { 'textarea' }
    data_option do
      {
        'type'      => 'textarea',
        'maxlength' => 255,
        'rows'      => 4,
        'null'      => true,
        'translate' => false,
        'default'   => default,
        'options'   => {},
        'relation'  => '',
      }
    end
  end

  factory :object_manager_attribute_integer, parent: :object_manager_attribute do
    default { 0 }

    data_type { 'integer' }
    data_option do
      {
        'default' => default,
        'min'     => 0,
        'max'     => 9999,
      }
    end
  end

  factory :object_manager_attribute_boolean, parent: :object_manager_attribute do
    default { false }

    data_type { 'boolean' }
    data_option do
      {
        default: default,
        options: {
          true  => 'yes',
          false => 'no',
        }
      }
    end
  end

  factory :object_manager_attribute_date, parent: :object_manager_attribute do
    default { 24 }

    name      { 'date_attribute' }
    data_type { 'date' }
    data_option do
      {
        'diff' => default,
        'null' => true,
      }
    end
  end

  factory :object_manager_attribute_datetime, parent: :object_manager_attribute do
    default { 24 }

    name      { 'datetime_attribute' }
    data_type { 'datetime' }
    data_option do
      {
        'future' => true,
        'past'   => true,
        'diff'   => default,
        'null'   => true,
      }
    end
  end

  factory :object_manager_attribute_select, parent: :object_manager_attribute do
    transient do
      data_option_options do
        {
          'key_1' => 'value_1',
          'key_2' => 'value_2',
          'key_3' => 'value_3',
        }
      end
    end

    default { '' }

    data_type { 'select' }
    data_option do
      {
        'default'    => default,
        'options'    => data_option_options,
        'relation'   => '',
        'nulloption' => true,
        'multiple'   => false,
        'null'       => true,
        'translate'  => true,
        'maxlength'  => 255
      }
    end
  end

  factory :object_manager_attribute_multiselect, parent: :object_manager_attribute do
    transient do
      data_option_options do
        {
          'key_1' => 'value_1',
          'key_2' => 'value_2',
          'key_3' => 'value_3',
        }
      end
    end

    default { [] }

    data_type { 'multiselect' }
    data_option do
      {
        'default'    => default,
        'options'    => data_option_options,
        'relation'   => '',
        'nulloption' => true,
        'multiple'   => true,
        'null'       => true,
        'translate'  => true,
        'maxlength'  => 255
      }
    end
  end

  factory :object_manager_attribute_tree_select, parent: :object_manager_attribute do
    default { '' }

    data_type { 'tree_select' }
    data_option do
      {
        'options'    => [
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
                    'name'  => 'EDI',
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

  factory :object_manager_attribute_multi_tree_select, parent: :object_manager_attribute do
    default { [] }

    data_type { 'multi_tree_select' }
    data_option do
      {
        'options'    => [
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
                    'name'  => 'EDI',
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
        'multiple'   => true,
      }
    end
  end

  factory :object_manager_attribute_user_autocompletion, parent: :object_manager_attribute do
    default { '' }

    data_type { 'user_autocompletion' }
    data_option do
      {
        'relation'       => 'User',
        'autocapitalize' => false,
        'multiple'       => false,
        'guess'          => true,
        'null'           => false,
        'limit'          => 200,
        'placeholder'    => 'Enter Person or Organization/Company',
        'minLengt'       => 2,
        'translate'      => false,
        'permission'     => ['ticket.agent']
      }
    end
  end

  factory :object_manager_attribute_organization_autocompletion, parent: :object_manager_attribute do
    default { '' }

    data_type { 'autocompletion_ajax_customer_organization' }
    data_option do
      {
        'relation'       => 'Organization',
        'autocapitalize' => false,
        'multiple'       => false,
        'null'           => true,
        'translate'      => false,
        'permission'     => ['ticket.agent', 'ticket.customer']
      }
    end
  end

  factory :object_manager_attribute_autocompletion_ajax_external_data_source, parent: :object_manager_attribute do
    transient do
      search_url   { 'http://example.search?q=#{search.term}' } # rubocop:disable Lint/InterpolationCheck
      list_key     { 'list' }
      value_key    { 'id' }
      label_key    { 'name' }
      linktemplate { '' }
    end

    default { [] }

    data_type { 'autocompletion_ajax_external_data_source' }
    data_option do
      {
        'null'                    => true,
        'search_url'              => search_url,
        'search_result_list_key'  => list_key,
        'search_result_value_key' => value_key,
        'search_result_label_key' => label_key,
        'linktemplate'            => linktemplate,
      }
    end

    trait :elastic_search do
      transient do
        search_url   { "#{Setting.get('es_url')}/#{Setting.get('es_index')}_test_user/_search?q=\#{search.term}&sort=id" }
        list_key     { 'hits.hits' }
        value_key    { '_id' }
        label_key    { '_source.email' }
        linktemplate { "#{Setting.get('http_type')}://#{Setting.get('fqdn')}/#user/profile/\#{#{object_name.downcase}.#{name}}" }
      end
    end
  end
end
