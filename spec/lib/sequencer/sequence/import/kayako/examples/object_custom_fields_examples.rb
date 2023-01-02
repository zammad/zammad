# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

RSpec.shared_examples 'Object custom fields' do |klass:|
  let(:process_payload) do
    {
      import_job:       build_stubbed(:import_job, name: 'Import::Kayako', payload: {}),
      dry_run:          false,
      resource:         resource,
      field_map:        {},
      id_map:           {},
      default_language: 'en-us',
    }
  end

  shared_examples 'import valid custom field' do |field_name|
    it 'add custom field' do
      expect { process(process_payload) }.to change(klass, :column_names).by([field_name])
    end
  end

  shared_examples 'import skipped custom field' do
    it 'ignore custom field' do
      expect { process(process_payload) }.not_to change(klass, :column_names)
    end
  end

  context "when custom field type is 'TEXT'" do
    let(:resource) do
      {
        'id'                        => 80_000_387_409,
        'fielduuid'                 => '82e5393b-e036-45d1-beb9-46f96ebd697a',
        'title'                     => 'Textfield',
        'type'                      => 'TEXT',
        'key'                       => 'custom_textfield',
        'is_visible_to_customers'   => false,
        'required_for_agents'       => true,
        'is_customer_editable'      => false,
        'is_required_for_customers' => false,
        'regular_expression'        => nil,
        'sort_order'                => 1,
        'is_enabled'                => true,
        'options'                   => [],
        'created_at'                => '2021-08-16T19:34:35+00:00',
        'updated_at'                => '2021-08-16T19:34:35+00:00',
      }
    end

    include_examples 'import valid custom field', 'custom_textfield'
  end

  context 'when custom field should be skipped' do
    let(:resource) do
      {
        'id'                        => 80_000_387_409,
        'fielduuid'                 => '82e5393b-e036-45d1-beb9-46f96ebd697a',
        'title'                     => 'Name',
        'type'                      => 'TEXT',
        'key'                       => 'name',
        'is_visible_to_customers'   => false,
        'required_for_agents'       => true,
        'is_customer_editable'      => false,
        'is_required_for_customers' => false,
        'regular_expression'        => nil,
        'sort_order'                => 1,
        'is_enabled'                => true,
        'is_system'                 => true,
        'options'                   => [],
        'created_at'                => '2021-08-16T19:34:35+00:00',
        'updated_at'                => '2021-08-16T19:34:35+00:00',
      }
    end

    include_examples 'import skipped custom field'
  end

  context "when custom field type is 'SELECT'" do
    let(:resource) do
      {
        'id'                        => 80_000_387_409,
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
      }
    end

    include_examples 'import valid custom field', 'custom_singleselection'
  end

  context "when custom field type is 'CASCADINGSELECT'" do
    let(:resource) do
      {
        'id'                        => 80_000_387_409,
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
      }
    end

    include_examples 'import valid custom field', 'custom_tree_select'
  end

  context "when custom field type is 'CHECKBOX'" do
    let(:resource) do
      {
        'id'                        => 80_000_387_409,
        'fielduuid'                 => 'ff7093f3-ad44-4519-80b0-f9b1a9988ac0',
        'title'                     => 'Multichoice',
        'type'                      => 'CHECKBOX',
        'key'                       => 'custom_multichoice',
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
      }
    end

    include_examples 'import valid custom field', 'custom_multichoice'
  end
end
