# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'
require 'lib/import/otrs/dynamic_field_examples'

RSpec.describe Import::OTRS::DynamicField::Multiselect do
  it_behaves_like 'Import::OTRS::DynamicField'

  it 'imports an OTRS Multiselect DynamicField' do

    zammad_structure = {
      object:        'Ticket',
      name:          'multiselect_example',
      display:       'Multiselec tExample',
      screens:       {
        view: {
          '-all-' => {
            shown: true
          }
        }
      },
      active:        true,
      editable:      true,
      position:      '4',
      created_by_id: 1,
      updated_by_id: 1,
      data_type:     'select',
      data_option:   {
        default:    '',
        multiple:   true,
        options:    {
          'Hamburg' => 'Hamburg',
          'München' => 'München',
          'Köln'    => 'Köln',
          'Berlin'  => 'Berlin'
        },
        nulloption: false,
        null:       true,
        translate:  false
      }
    }

    dynamic_field_from_json('multiselect/default', zammad_structure)
  end
end
