# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Sequencer::Sequence::Import::Freshdesk::Company, db_strategy: :reset, sequencer: :sequence do

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

    let(:imported_organization) do
      {
        name:               'Test Foundation',
        note:               nil,
        domain:             'acmecorp.com',
        cf_custom_dropdown: 'key_2',
        cf_custom_integer:  999,
        cf_test_checkbox:   true,
        cf_custom_decimal:  '1.1',
      }
    end

    before do
      create(:object_manager_attribute_select, object_name: 'Organization', name:  'cf_custom_dropdown')
      create(:object_manager_attribute_integer, object_name: 'Organization', name: 'cf_custom_integer')
      create(:object_manager_attribute_boolean, object_name: 'Organization', name: 'cf_test_checkbox')
      create(:object_manager_attribute_text, object_name: 'Organization', name: 'cf_custom_decimal')
      ObjectManager::Attribute.migration_execute
    end

    it 'increased organization count' do
      expect { process(process_payload) }.to change(Organization, :count).by(1)
    end

    it 'adds correct organization data' do
      process(process_payload)
      expect(Organization.last).to have_attributes(imported_organization)
    end

    context 'when resource has no domains' do
      let(:resource) do
        { 'id'            => 80_000_602_705,
          'name'          => 'Test Foundation',
          'description'   => nil,
          'note'          => nil,
          'domains'       => [],
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

      before do
        imported_organization[:domain] = nil
      end

      it 'adds organizations' do
        process(process_payload)
        expect(Organization.last).to have_attributes(imported_organization)
      end
    end
  end
end
