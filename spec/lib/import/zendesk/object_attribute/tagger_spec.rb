# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'
require 'lib/import/zendesk/object_attribute/base_examples'

RSpec.describe Import::Zendesk::ObjectAttribute::Tagger do
  it_behaves_like Import::Zendesk::ObjectAttribute::Base

  it 'imports select object attribute from tagger object field' do

    attribute = double(
      title:                'Example attribute',
      description:          'Example attribute description',
      removable:            false,
      active:               true,
      position:             12,
      visible_in_portal:    true,
      required_in_portal:   true,
      required:             true,
      type:                 'tagger',
      custom_field_options: [
        {
          'id'    => 1,
          'value' => 'Key 1',
          'name'  => 'Value 1'
        },
        {
          'id'    => 2,
          'value' => 'Key 2',
          'name'  => 'Value 2'
        },
      ]
    )

    expected_structure = {
      object:        'Ticket',
      name:          'example_field',
      display:       'Example attribute',
      data_type:     'select',
      data_option:   {
        null:    false,
        note:    'Example attribute description',
        default: '',
        options: {
          'Key 1' => 'Value 1',
          'Key 2' => 'Value 2'
        },
      },
      editable:      true,
      active:        true,
      screens:       {
        edit: {
          Customer: {
            shown: true,
            null:  false
          },
          view:     {
            '-all-' => {
              shown: true
            }
          }
        }
      },
      position:      12,
      created_by_id: 1,
      updated_by_id: 1
    }

    expect(ObjectManager::Attribute).to receive(:add).with(expected_structure)
    expect(ObjectManager::Attribute).to receive(:migration_execute)

    described_class.new('Ticket', 'example_field', attribute)
  end
end
