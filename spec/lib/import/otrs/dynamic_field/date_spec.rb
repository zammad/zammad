# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'
require 'lib/import/otrs/dynamic_field_examples'

# this require is required (hehe) because of Rails autoloading
# which causes this error:
# warning: toplevel constant Date referenced by Import::OTRS::DynamicField::Date
# and rspec thinks we want to test Date and stores it into described_class...
require 'import/otrs/dynamic_field/date'

RSpec.describe Import::OTRS::DynamicField::Date do
  it_behaves_like 'Import::OTRS::DynamicField'

  it 'imports an OTRS Date DynamicField' do

    zammad_structure = {
      object:        'Ticket',
      name:          'date_example',
      display:       'Date Example',
      screens:       {
        view: {
          '-all-' => {
            shown: true
          }
        }
      },
      active:        true,
      editable:      true,
      position:      '40',
      created_by_id: 1,
      updated_by_id: 1,
      data_type:     'date',
      data_option:   {
        future: false,
        past:   false,
        diff:   0,
        null:   true
      }
    }

    dynamic_field_from_json('date/default', zammad_structure)
  end
end
