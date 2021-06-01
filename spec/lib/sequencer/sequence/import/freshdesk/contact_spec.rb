# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe ::Sequencer::Sequence::Import::Freshdesk::Contact, sequencer: :sequence, db_strategy: :reset do

  context 'when importing customers from Freshdesk' do

    let(:resource) do
      {
        'active'           => false,
        'address'          => nil,
        'company_id'       => 1001,
        'description'      => nil,
        'email'            => 'sam.ozzy@freshdesk.com',
        'id'               => 80_014_400_819,
        'job_title'        => nil,
        'language'         => 'en',
        'mobile'           => nil,
        'name'             => 'Sam Osborne',
        'phone'            => nil,
        'time_zone'        => 'Eastern Time (US & Canada)',
        'twitter_id'       => nil,
        'custom_fields'    => {
          'cf_test_checkbox'   => true,
          'cf_custom_integer'  => 999,
          'cf_custom_dropdown' => 'key_2',
          'cf_custom_decimal'  => '1.1',
        },
        'facebook_id'      => nil,
        'created_at'       => '2021-04-09T13:29:43Z',
        'updated_at'       => '2021-04-09T13:29:43Z',
        'csat_rating'      => 103,
        'preferred_source' => 'email',
      }
    end

    let(:field_map) do
      {
        'User' => {
          'cf_test_checkbox'   => 'cf_test_checkbox',
          'cf_custom_integer'  => 'cf_custom_integer',
          'cf_custom_dropdown' => 'cf_custom_dropdown',
          'cf_custom_decimal'  => 'cf_custom_decimal'
        }
      }
    end

    let(:id_map) do
      {
        'Organization' => { 1001 => 1 }
      }
    end

    let(:process_payload) do
      {
        import_job: build_stubbed(:import_job, name: 'Import::Freshdesk', payload: {}),
        dry_run:    false,
        resource:   resource,
        field_map:  field_map,
        id_map:     id_map,
      }
    end

    before do
      create :object_manager_attribute_select, object_name: 'User', name:  'cf_custom_dropdown'
      create :object_manager_attribute_integer, object_name: 'User', name: 'cf_custom_integer'
      create :object_manager_attribute_boolean, object_name: 'User', name: 'cf_test_checkbox'
      create :object_manager_attribute_text, object_name: 'User', name: 'cf_custom_decimal'
      ObjectManager::Attribute.migration_execute
    end

    it 'imports customers correctly' do # rubocop:disable RSpec/MultipleExpectations, RSpec/ExampleLength
      expect { process(process_payload) }.to change(User, :count).by(1)
      expect(User.last).to have_attributes(
        firstname:          'Sam',
        lastname:           'Osborne',
        login:              'sam.ozzy@freshdesk.com',
        email:              'sam.ozzy@freshdesk.com',
        active:             false,
        cf_custom_dropdown: 'key_2',
        cf_custom_integer:  999,
        cf_test_checkbox:   true,
        cf_custom_decimal:  '1.1',
      )
    end
  end
end
