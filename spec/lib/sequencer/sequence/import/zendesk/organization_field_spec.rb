# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'zendesk_api'

RSpec.describe Sequencer::Sequence::Import::Zendesk::OrganizationField, sequencer: :sequence do

  context 'when trying to import organization fields from Zendesk', db_strategy: :reset do

    let(:process_payload) do
      {
        import_job: build_stubbed(:import_job, name: 'Import::Zendesk', payload: {}),
        dry_run:    false,
        resource:   resource,
        field_map:  {},
      }
    end

    let(:resource) do
      ZendeskAPI::OrganizationField.new(
        nil,
        {
          'id'                    => 207_489,
          'type'                  => 'text',
          'key'                   => 'api_key',
          'title'                 => 'API Key',
          'description'           => 'Der API Key für externe Zugriffe.',
          'raw_title'             => 'API Key',
          'raw_description'       => 'Der API Key für externe Zugriffe.',
          'position'              => 0,
          'active'                => true,
          'system'                => false,
          'regexp_for_validation' => nil,
          'created_at'            => '2015-12-04 11:24:08 UTC',
          'updated_at'            => '2015-12-04 11:24:08 UTC'
        }
      )
    end

    it 'adds custom fields' do
      expect { process(process_payload) }.to change(Organization, :column_names).by(['api_key'])
    end
  end
end
