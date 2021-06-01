# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'
require 'lib/import/zendesk/object_attribute/base_examples'

# required due to some of rails autoloading issues
require 'import/zendesk/object_attribute/date'

RSpec.describe Import::Zendesk::ObjectAttribute::Date do
  it_behaves_like Import::Zendesk::ObjectAttribute::Base

  it 'imports date object attribute from date object field' do

    attribute = double(
      title:              'Example attribute',
      description:        'Example attribute description',
      removable:          false,
      active:             true,
      position:           12,
      visible_in_portal:  true,
      required_in_portal: true,
      required:           true,
      type:               'date',
    )

    expected_structure = {
      object:        'Ticket',
      name:          'example_field',
      display:       'Example attribute',
      data_type:     'date',
      data_option:   {
        null:   false,
        note:   'Example attribute description',
        future: true,
        past:   true,
        diff:   0,
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
