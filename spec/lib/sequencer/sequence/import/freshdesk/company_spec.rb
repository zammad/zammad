# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe ::Sequencer::Sequence::Import::Freshdesk::Company, sequencer: :sequence, db_strategy: :reset do

  context 'when importing companies from Freshdesk' do

    let(:resource) do
      { 'id'            => 80_000_602_705,
        'name'          => 'Test Foundation',
        'description'   => nil,
        'note'          => nil,
        'domains'       => ['acmecorp.com'],
        'created_at'    => '2021-04-09T13:24:00Z',
        'updated_at'    => '2021-04-12T20:25:36Z',
        'custom_fields' => {
          'cf_test_checkbox'   => true,
          'cf_custom_integer'  => 999,
          'cf_custom_dropdown' => 'key_2',
          'cf_custom_decimal'  => '1.1',
        },
        'health_score'  => nil,
        'account_tier'  => 'Basic',
        'renewal_date'  => nil,
        'industry'      => nil }
    end

    let(:field_map) do
      {
        'Organization' => {
          'cf_test_checkbox'   => 'cf_test_checkbox',
          'cf_custom_integer'  => 'cf_custom_integer',
          'cf_custom_dropdown' => 'cf_custom_dropdown',
          'cf_custom_decimal'  => 'cf_custom_decimal'
        }
      }
    end

    let(:process_payload) do
      {
        import_job: build_stubbed(:import_job, name: 'Import::Freshdesk', payload: {}),
        dry_run:    false,
        resource:   resource,
        field_map:  field_map,
        id_map:     {},
      }
    end

    before do
      create :object_manager_attribute_select, object_name: 'Organization', name:  'cf_custom_dropdown'
      create :object_manager_attribute_integer, object_name: 'Organization', name: 'cf_custom_integer'
      create :object_manager_attribute_boolean, object_name: 'Organization', name: 'cf_test_checkbox'
      create :object_manager_attribute_text, object_name: 'Organization', name: 'cf_custom_decimal'
      ObjectManager::Attribute.migration_execute
    end

    it 'adds organizations' do # rubocop:disable RSpec/MultipleExpectations, RSpec/ExampleLength
      expect { process(process_payload) }.to change(Organization, :count).by(1)
      expect(Organization.last).to have_attributes(
        name:               'Test Foundation',
        note:               nil,
        cf_custom_dropdown: 'key_2',
        cf_custom_integer:  999,
        cf_test_checkbox:   true,
        cf_custom_decimal:  '1.1',
      )
    end
  end
end
