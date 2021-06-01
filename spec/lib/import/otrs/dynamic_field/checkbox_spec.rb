# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'
require 'lib/import/otrs/dynamic_field_examples'

RSpec.describe Import::OTRS::DynamicField::Checkbox do
  it_behaves_like 'Import::OTRS::DynamicField'

  it 'imports an OTRS Checkbox DynamicField' do

    zammad_structure = {
      object:        'Ticket',
      name:          'checkbox_example',
      display:       'Checkbox Example',
      screens:       {
        view: {
          '-all-' => {
            shown: true
          }
        }
      },
      active:        true,
      editable:      true,
      position:      '26',
      created_by_id: 1,
      updated_by_id: 1,
      data_type:     'boolean',
      data_option:   {
        default:   true,
        options:   {
          true  => 'Yes',
          false => 'No'
        },
        null:      true,
        translate: true
      }
    }

    dynamic_field_from_json('checkbox/default', zammad_structure)
  end
end
