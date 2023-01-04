# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'zendesk_api'

RSpec.describe Sequencer::Sequence::Import::Zendesk::Organization, db_strategy: :reset, sequencer: :sequence do

  context 'when importing organizations from Zendesk' do

    let(:resource) do
      ZendeskAPI::Organization.new(
        nil,
        {
          'id'                  => 154_755_561,
          'name'                => 'Test Foundation',
          'shared_tickets'      => false,
          'shared_comments'     => false,
          'external_id'         => nil,
          'created_at'          => '2015-07-19 22:41:40 UTC',
          'updated_at'          => '2016-05-19 12:24:21 UTC',
          'domain_names'        => [],
          'details'             => '',
          'notes'               => '',
          'group_id'            => nil,
          'tags'                => ['b'],
          'organization_fields' => {
            'api_key'         => 'my api öäüß',
            'custom_dropdown' => 'b',
            'test::example'   => '1',
          },
          'deleted_at'          => nil
        }
      )
    end

    let(:field_map) do
      {
        'Organization' => {
          'api_key'         => 'api_key',
          'custom_dropdown' => 'custom_dropdown',
          'test::example'   => 'test_example',
        }
      }
    end

    let(:process_payload) do
      {
        import_job: build_stubbed(:import_job, name: 'Import::Zendesk', payload: {}),
        dry_run:    false,
        resource:   resource,
        field_map:  field_map,
      }
    end

    let(:imported_organization) do
      {
        name:            'Test Foundation',
        note:            nil,
        domain:          '',
        api_key:         'my api öäüß',
        custom_dropdown: 'b',
        test_example:    '1',
      }
    end

    before do
      create(:object_manager_attribute_select, object_name: 'Organization', name: 'custom_dropdown')
      create(:object_manager_attribute_text, object_name: 'Organization', name: 'api_key')
      create(:object_manager_attribute_text, object_name: 'Organization', name: 'test_example')
      ObjectManager::Attribute.migration_execute
    end

    it 'increased organization count' do
      expect { process(process_payload) }.to change(Organization, :count).by(1)
    end

    it 'adds correct organization data' do
      process(process_payload)
      expect(Organization.last).to have_attributes(imported_organization)
    end
  end
end
