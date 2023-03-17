# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'lib/import/otrs/dynamic_field_examples'

RSpec.describe Import::OTRS::DynamicField::Multiselect, mariadb: true do
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
      data_type:     'multiselect',
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

  context 'without possible values' do
    it 'imports no field without possible value' do
      allow(ObjectManager::Attribute).to receive(:add)

      described_class.new(load_dynamic_field_json('multiselect/without_possible_values'))

      expect(ObjectManager::Attribute).not_to have_received(:add)
    end
  end
end
