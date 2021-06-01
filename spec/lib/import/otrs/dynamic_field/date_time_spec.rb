# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'
require 'lib/import/otrs/dynamic_field_examples'

# this require is required (hehe) because of Rails autoloading
# which causes this error:
# warning: toplevel constant DateTime referenced by Import::OTRS::DynamicField::DateTime
# and rspec thinks we want to test Date and stores it into described_class...
require 'import/otrs/dynamic_field/date_time'

RSpec.describe Import::OTRS::DynamicField::DateTime do
  it_behaves_like 'Import::OTRS::DynamicField'

  it 'imports an OTRS DateTime DynamicField' do

    zammad_structure = {
      object:        'Ticket',
      name:          'date_time_example',
      display:       'DateTime Example',
      screens:       {
        view: {
          '-all-' => {
            shown: true
          }
        }
      },
      active:        true,
      editable:      false,
      position:      '16',
      created_by_id: 1,
      updated_by_id: 1,
      data_type:     'datetime',
      data_option:   {
        future: true,
        past:   true,
        diff:   72,
        null:   true
      }
    }

    dynamic_field_from_json('date_time/default', zammad_structure)
  end
end
