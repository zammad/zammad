# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'
require 'lib/import/otrs/dynamic_field_examples'

RSpec.describe Import::OTRS::DynamicField::TextArea do
  it_behaves_like 'Import::OTRS::DynamicField'

  it 'imports an OTRS TextArea DynamicField' do

    zammad_structure = {
      object:        'Ticket',
      name:          'text_area_example',
      display:       'TextArea Example',
      screens:       {
        view: {
          '-all-' => {
            shown: true
          }
        }
      },
      active:        true,
      editable:      true,
      position:      '8',
      created_by_id: 1,
      updated_by_id: 1,
      data_type:     'textarea',
      data_option:   {
        default: '',
        rows:    '20',
        null:    true
      }
    }

    dynamic_field_from_json('text_area/default', zammad_structure)
  end
end
