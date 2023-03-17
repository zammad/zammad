# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

RSpec.shared_examples 'Object custom field values', db_strategy: :reset do |object_name:, klass:|

  let(:resource) do
    super().merge(
      'custom_fields' => [
        {
          'field' => {
            'id'                        => 1,
            'fielduuid'                 => '82e5393b-e036-45d1-beb9-46f96ebd697a',
            'title'                     => 'Textfield',
            'type'                      => 'TEXT',
            'key'                       => 'custom_textfield',
            'is_visible_to_customers'   => false,
            'is_customer_editable'      => false,
            'is_required_for_customers' => false,
            'regular_expression'        => nil,
            'sort_order'                => 1,
            'is_enabled'                => true,
            'options'                   => [],
            'created_at'                => '2021-08-16T19:34:35+00:00',
            'updated_at'                => '2021-08-16T19:34:35+00:00',
          },
          'value' => 'Testing',
        },
        {
          'field' => {
            'id'                        => 2,
            'fielduuid'                 => 'ff7093f3-ad44-4519-80b0-f9b1a9988ac0',
            'title'                     => 'Singleselection',
            'type'                      => 'SELECT',
            'key'                       => 'custom_singleselection',
            'is_visible_to_customers'   => false,
            'is_customer_editable'      => false,
            'is_required_for_customers' => false,
            'regular_expression'        => nil,
            'sort_order'                => 2,
            'is_enabled'                => true,
            'options'                   => [
              {
                'id'         => 1,
                'fielduuid'  => 'ff7093f3-ad44-4519-80b0-f9b1a9988ac0',
                'values'     => [
                  {
                    'id'          => 26,
                    'locale'      => 'en-us',
                    'translation' => 'one',
                    'created_at'  => '2021-08-16T19:35:02+00:00',
                    'updated_at'  => '2021-08-16T19:35:02+00:00',
                  }
                ],
                'sort_order' => 0,
                'created_at' => '2021-08-16T19:35:02+00:00',
                'updated_at' => '2021-08-16T19:35:02+00:00',
              },
              {
                'id'         => 2,
                'fielduuid'  => 'ff7093f3-ad44-4519-80b0-f9b1a9988ac0',
                'values'     => [
                  {
                    'id'          => 27,
                    'locale'      => 'en-us',
                    'translation' => 'two',
                    'created_at'  => '2021-08-16T19:35:02+00:00',
                    'updated_at'  => '2021-08-16T19:35:02+00:00',
                  }
                ],
                'sort_order' => 0,
                'created_at' => '2021-08-16T19:35:02+00:00',
                'updated_at' => '2021-08-16T19:35:02+00:00',
              },
              {
                'id'         => 3,
                'fielduuid'  => 'ff7093f3-ad44-4519-80b0-f9b1a9988ac0',
                'values'     => [
                  {
                    'id'          => 25,
                    'locale'      => 'en-us',
                    'translation' => 'three',
                    'created_at'  => '2021-08-16T19:35:01+00:00',
                    'updated_at'  => '2021-08-16T19:35:01+00:00',
                  }
                ],
                'sort_order' => 0,
                'created_at' => '2021-08-16T19:35:01+00:00',
                'updated_at' => '2021-08-16T19:35:01+00:00',
              },
            ],
            'created_at'                => '2021-08-16T19:35:01+00:00',
            'updated_at'                => '2021-08-17T14:32:50+00:00',
          },
          'value' => '2',
        },
        {
          'field' => {
            'id'                        => 4,
            'fielduuid'                 => 'ff7093f3-ad44-4519-80b0-f9b1a9988ac0',
            'title'                     => 'Multiselection',
            'type'                      => 'CHECKBOX',
            'key'                       => 'custom_multiselection',
            'is_visible_to_customers'   => false,
            'is_customer_editable'      => false,
            'is_required_for_customers' => false,
            'regular_expression'        => nil,
            'sort_order'                => 2,
            'is_enabled'                => true,
            'options'                   => [
              {
                'id'         => 1,
                'fielduuid'  => 'ff7093f3-ad44-4519-80b0-f9b1a9988ac0',
                'values'     => [
                  {
                    'id'          => 26,
                    'locale'      => 'en-us',
                    'translation' => 'one',
                    'created_at'  => '2021-08-16T19:35:02+00:00',
                    'updated_at'  => '2021-08-16T19:35:02+00:00',
                  }
                ],
                'sort_order' => 0,
                'created_at' => '2021-08-16T19:35:02+00:00',
                'updated_at' => '2021-08-16T19:35:02+00:00',
              },
              {
                'id'         => 2,
                'fielduuid'  => 'ff7093f3-ad44-4519-80b0-f9b1a9988ac0',
                'values'     => [
                  {
                    'id'          => 27,
                    'locale'      => 'en-us',
                    'translation' => 'two',
                    'created_at'  => '2021-08-16T19:35:02+00:00',
                    'updated_at'  => '2021-08-16T19:35:02+00:00',
                  }
                ],
                'sort_order' => 0,
                'created_at' => '2021-08-16T19:35:02+00:00',
                'updated_at' => '2021-08-16T19:35:02+00:00',
              },
              {
                'id'         => 3,
                'fielduuid'  => 'ff7093f3-ad44-4519-80b0-f9b1a9988ac0',
                'values'     => [
                  {
                    'id'          => 25,
                    'locale'      => 'en-us',
                    'translation' => 'three',
                    'created_at'  => '2021-08-16T19:35:01+00:00',
                    'updated_at'  => '2021-08-16T19:35:01+00:00',
                  }
                ],
                'sort_order' => 0,
                'created_at' => '2021-08-16T19:35:01+00:00',
                'updated_at' => '2021-08-16T19:35:01+00:00',
              },
            ],
            'created_at'                => '2021-08-16T19:35:01+00:00',
            'updated_at'                => '2021-08-17T14:32:50+00:00',
          },
          'value' => '2,3',
        },
        {
          'field' => {
            'id'                        => 5,
            'fielduuid'                 => '317664dc-66d6-4d60-9814-64905a7e2fb8',
            'title'                     => 'Available?',
            'type'                      => 'YESNO',
            'key'                       => 'custom_boolean',
            'is_visible_to_customers'   => false,
            'is_customer_editable'      => false,
            'is_required_for_customers' => false,
            'regular_expression'        => nil,
            'sort_order'                => 5,
            'is_enabled'                => true,
            'options'                   => [],
            'created_at'                => '2021-08-16T19:35:43+00:00',
            'updated_at'                => '2021-08-16T19:35:43+00:00',
          },
          'value' => 'yes',
        },
        {
          'field' => {
            'id'                        => 6,
            'fielduuid'                 => 'b8d5fd67-b446-44a4-9559-f9f4b85c025a',
            'title'                     => 'Regex',
            'type'                      => 'REGEX',
            'key'                       => 'custom_text_regex',
            'is_visible_to_customers'   => false,
            'is_customer_editable'      => false,
            'is_required_for_customers' => false,
            'regular_expression'        => '\\d\\d\\d',
            'sort_order'                => 6,
            'is_enabled'                => true,
            'options'                   => [],
            'created_at'                => '2021-08-16T19:58:57+00:00',
            'updated_at'                => '2021-08-16T19:58:57+00:00',
          },
          'value' => '999',
        },
        {
          'field' => {
            'id'                        => 7,
            'fielduuid'                 => 'c06852f7-0c82-45af-9ce0-f5ac6e19db93',
            'title'                     => 'Textarea',
            'type'                      => 'TEXTAREA',
            'key'                       => 'custom_textarea',
            'is_visible_to_customers'   => false,
            'is_customer_editable'      => false,
            'is_required_for_customers' => false,
            'regular_expression'        => nil,
            'sort_order'                => 7,
            'is_enabled'                => true,
            'options'                   => [],
            'created_at'                => '2021-08-16T19:59:07+00:00',
            'updated_at'                => '2021-08-16T19:59:07+00:00',
          },
          'value' => 'Example textarea content.\nA new line.',
        },
        {
          'field' => {
            'id'                        => 8,
            'fielduuid'                 => 'e5346df5-55ec-4e15-aceb-3360c457aaca',
            'title'                     => 'Radio',
            'type'                      => 'RADIO',
            'key'                       => 'custom_radio',
            'is_visible_to_customers'   => false,
            'is_customer_editable'      => false,
            'is_required_for_customers' => false,
            'regular_expression'        => nil,
            'sort_order'                => 8,
            'is_enabled'                => true,
            'options'                   => [
              {
                'id'         => 7,
                'fielduuid'  => 'e5346df5-55ec-4e15-aceb-3360c457aaca',
                'values'     => [
                  {
                    'id'          => 43,
                    'locale'      => 'en-us',
                    'translation' => 'first',
                    'created_at'  => '2021-08-16T19:59:33+00:00',
                    'updated_at'  => '2021-08-16T19:59:33+00:00',
                  }
                ],
                'sort_order' => 0,
                'created_at' => '2021-08-16T19:59:33+00:00',
                'updated_at' => '2021-08-16T19:59:33+00:00',
              },
              {
                'id'         => 8,
                'fielduuid'  => 'e5346df5-55ec-4e15-aceb-3360c457aaca',
                'values'     => [
                  {
                    'id'          => 44,
                    'locale'      => 'en-us',
                    'translation' => 'second',
                    'created_at'  => '2021-08-16T19:59:33+00:00',
                    'updated_at'  => '2021-08-16T19:59:33+00:00',
                  }
                ],
                'sort_order' => 0,
                'created_at' => '2021-08-16T19:59:33+00:00',
                'updated_at' => '2021-08-16T19:59:33+00:00',
              },
              {
                'id'         => 9,
                'fielduuid'  => 'e5346df5-55ec-4e15-aceb-3360c457aaca',
                'values'     => [
                  {
                    'id'          => 45,
                    'locale'      => 'en-us',
                    'translation' => 'third',
                    'created_at'  => '2021-08-16T19:59:33+00:00',
                    'updated_at'  => '2021-08-16T19:59:33+00:00',
                  }
                ],
                'sort_order' => 0,
                'created_at' => '2021-08-16T19:59:33+00:00',
                'updated_at' => '2021-08-16T19:59:33+00:00',
              }
            ],
            'created_at'                => '2021-08-16T19:59:33+00:00',
            'updated_at'                => '2021-08-17T14:45:10+00:00',
          },
          'value' => '9',
        },
        {
          'field' => {
            'id'                        => 9,
            'fielduuid'                 => '13a19707-29f0-4e97-8077-44be958c052c',
            'title'                     => 'Tree Select',
            'type'                      => 'CASCADINGSELECT',
            'key'                       => 'custom_tree_select',
            'is_visible_to_customers'   => false,
            'is_customer_editable'      => false,
            'is_required_for_customers' => false,
            'regular_expression'        => nil,
            'sort_order'                => 9,
            'is_enabled'                => true,
            'options'                   => [
              {
                'id'         => 10,
                'fielduuid'  => '13a19707-29f0-4e97-8077-44be958c052c',
                'values'     => [
                  {
                    'id'          => 48,
                    'locale'      => 'en-us',
                    'translation' => 'First-Level 1',
                    'created_at'  => '2021-08-16T19:59:52+00:00',
                    'updated_at'  => '2021-08-16T19:59:52+00:00',
                  }
                ],
                'sort_order' => 1,
                'created_at' => '2021-08-16T19:59:52+00:00',
                'updated_at' => '2021-08-16T20:02:03+00:00',
              },
              {
                'id'         => 11,
                'fielduuid'  => '13a19707-29f0-4e97-8077-44be958c052c',
                'values'     => [
                  {
                    'id'          => 49,
                    'locale'      => 'en-us',
                    'translation' => 'First-Level 2\\Second-Level 1',
                    'created_at'  => '2021-08-16T19:59:52+00:00',
                    'updated_at'  => '2021-08-16T20:05:31+00:00',
                  }
                ],
                'sort_order' => 2,
                'created_at' => '2021-08-16T19:59:52+00:00',
                'updated_at' => '2021-08-16T20:02:03+00:00',
              },
              {
                'id'         => 22,
                'fielduuid'  => '13a19707-29f0-4e97-8077-44be958c052c',
                'values'     => [
                  {
                    'id'          => 427,
                    'locale'      => 'en-us',
                    'translation' => 'First-Level 2\\Second-Level 2',
                    'created_at'  => '2021-08-18T09:41:09+00:00',
                    'updated_at'  => '2021-08-18T13:10:05+00:00',
                  }
                ],
                'sort_order' => 3,
                'created_at' => '2021-08-18T09:41:09+00:00',
                'updated_at' => '2021-08-18T09:41:54+00:00',
              },
              {
                'id'         => 12,
                'fielduuid'  => '13a19707-29f0-4e97-8077-44be958c052c',
                'values'     => [
                  {
                    'id'          => 50,
                    'locale'      => 'en-us',
                    'translation' => 'First-Level 3',
                    'created_at'  => '2021-08-16T19:59:52+00:00',
                    'updated_at'  => '2021-08-16T19:59:52+00:00',
                  }
                ],
                'sort_order' => 5,
                'created_at' => '2021-08-16T19:59:52+00:00',
                'updated_at' => '2021-08-18T09:41:54+00:00',
              },
            ],
            'created_at'                => '2021-08-16T19:59:52+00:00',
            'updated_at'                => '2021-08-18T13:10:05+00:00',
          },
          'value' => '22',
        },
        {
          'field' => {
            'id'                        => 10,
            'fielduuid'                 => '0c4f20ce-5db4-4e78-83d7-9fb9c7ac62b7',
            'title'                     => 'Decimal',
            'type'                      => 'DECIMAL',
            'key'                       => 'custom_text_decimal',
            'is_visible_to_customers'   => false,
            'is_customer_editable'      => false,
            'is_required_for_customers' => false,
            'regular_expression'        => nil,
            'sort_order'                => 10,
            'is_enabled'                => true,
            'options'                   => [],
            'created_at'                => '2021-08-16T20:01:01+00:00',
            'updated_at'                => '2021-08-16T20:01:01+00:00',
          },
          'value' => '3.5',
        },
        {
          'field' => {
            'id'                        => 11,
            'fielduuid'                 => '1a2aa5f9-8128-43be-abe9-8128fcc41005',
            'title'                     => 'Numeric',
            'type'                      => 'NUMERIC',
            'key'                       => 'custom_integer',
            'is_visible_to_customers'   => false,
            'is_customer_editable'      => false,
            'is_required_for_customers' => false,
            'regular_expression'        => nil,
            'sort_order'                => 11,
            'is_enabled'                => true,
            'options'                   => [],
            'created_at'                => '2021-08-16T20:01:07+00:00',
            'updated_at'                => '2021-08-16T20:01:07+00:00',
          },
          'value' => '3',
        },
        {
          'field' => {
            'id'                        => 12,
            'fielduuid'                 => '63b3eff6-9405-4857-aa2b-4e1e4639e283',
            'title'                     => 'Attachment',
            'type'                      => 'FILE',
            'key'                       => 'attachment',
            'is_visible_to_customers'   => true,
            'is_customer_editable'      => true,
            'is_required_for_customers' => true,
            'descriptions'              => [],
            'regular_expression'        => nil,
            'sort_order'                => 12,
            'is_enabled'                => true,
            'options'                   => [],
            'created_at'                => '2021-08-16T20:59:03+00:00',
            'updated_at'                => '2021-08-16T20:59:03+00:00',
          },
          'value' => '',
        },
        {
          'field' => {
            'id'                        => 13,
            'fielduuid'                 => 'bc9d1be5-9a7b-4581-90be-59e75a4e660d',
            'title'                     => 'Founding Date',
            'type'                      => 'DATE',
            'key'                       => 'custom_date',
            'is_visible_to_customers'   => false,
            'is_customer_editable'      => false,
            'is_required_for_customers' => false,
            'regular_expression'        => nil,
            'sort_order'                => 13,
            'is_enabled'                => true,
            'options'                   => [],
            'created_at'                => '2021-08-17T20:33:18+00:00',
            'updated_at'                => '2021-08-17T20:33:18+00:00',
          },
          'value' => '2021-08-13T00:00:00+00:00',
        }
      ],
    )
  end

  let(:field_map) do
    {
      object_name => {
        'custom_textfield'       => 'custom_textfield',
        'custom_singleselection' => 'custom_singleselection',
        'custom_multiselection'  => 'custom_multiselection',
        'custom_boolean'         => 'custom_boolean',
        'custom_radio'           => 'custom_radio',
        'custom_text_regex'      => 'custom_text_regex',
        'custom_tree_select'     => 'custom_tree_select',
        'custom_textarea'        => 'custom_textarea',
        'custom_text_decimal'    => 'custom_text_decimal',
        'custom_integer'         => 'custom_integer',
        'custom_date'            => 'custom_date'
      }
    }
  end

  let(:process_payload) do
    super().merge(
      field_map: field_map
    )
  end

  let(:imported_resource_fields) do
    {
      custom_textfield:       'Testing',
      custom_singleselection: 'two',
      custom_multiselection:  %w[two three],
      custom_boolean:         true,
      custom_radio:           'third',
      custom_text_regex:      '999',
      custom_textarea:        'Example textarea content.\nA new line.',
      custom_tree_select:     'First-Level 2::Second-Level 2',
      custom_text_decimal:    '3.5',
      custom_integer:         3,
      custom_date:            Date.new(2021, 8, 13)
    }
  end

  before do
    create(:object_manager_attribute_text, object_name: object_name, name: 'custom_textfield')
    create(:object_manager_attribute_select, object_name: object_name, name: 'custom_singleselection')
    create(:object_manager_attribute_multiselect, object_name: object_name, name: 'custom_multiselection')
    create(:object_manager_attribute_boolean, object_name: object_name, name: 'custom_boolean')
    create(:object_manager_attribute_select, object_name: object_name, name: 'custom_radio')
    create(:object_manager_attribute_text, object_name: object_name, name: 'custom_text_regex')
    create(:object_manager_attribute_textarea, object_name: object_name, name: 'custom_textarea')
    create(:object_manager_attribute_tree_select, object_name: object_name, name: 'custom_tree_select')
    create(:object_manager_attribute_text, object_name: object_name, name: 'custom_text_decimal')
    create(:object_manager_attribute_integer, object_name: object_name, name: 'custom_integer')
    create(:object_manager_attribute_date, object_name: object_name, name: 'custom_date')
    ObjectManager::Attribute.migration_execute
  end

  it 'adds correct custom field data' do
    process(process_payload)
    expect(klass.last).to have_attributes(imported_resource_fields)
  end
end
