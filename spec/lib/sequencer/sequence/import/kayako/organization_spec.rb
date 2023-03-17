# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

require 'lib/sequencer/sequence/import/kayako/examples/object_custom_field_values_examples'

RSpec.describe Sequencer::Sequence::Import::Kayako::Organization, db_strategy: :reset, sequencer: :sequence do

  context 'when importing organizations from Kayako' do

    let(:resource) do
      {
        'id'                 => 80_000_602_705,
        'name'               => 'Test Foundation',
        'legacy_id'          => nil,
        'is_shared'          => false,
        'domains'            => [
          {
            'id'            => 3,
            'domain'        => 'test-foundation.com',
            'is_primary'    => true,
            'is_validated'  => false,
            'created_at'    => '2021-08-16T09:01:14+00:00',
            'updated_at'    => '2021-08-16T09:01:14+00:00',
            'resource_type' => 'identity_domain',
          }
        ],
        'is_validated'       => nil,
        'phone'              => [],
        'addresses'          => [],
        'websites'           => [],
        'pinned_notes_count' => 0,
        'created_at'         => '2021-08-16T09:01:14+00:00',
        'updated_at'         => '2021-08-18T20:37:52+00:00',
        'resource_type'      => 'organization',
      }
    end

    let(:process_payload) do
      {
        import_job:       build_stubbed(:import_job, name: 'Import::Kayako', payload: {}),
        dry_run:          false,
        resource:         resource,
        field_map:        {},
        id_map:           {},
        default_language: 'en-us',
      }
    end

    let(:imported_organization) do
      {
        name:              'Test Foundation',
        domain:            'test-foundation.com',
        domain_assignment: true,
      }
    end

    it 'increased organization count' do
      expect { process(process_payload) }.to change(Organization, :count).by(1)
    end

    it 'adds correct organization data' do
      process(process_payload)
      expect(Organization.last).to have_attributes(imported_organization)
    end

    context 'when importing custom fields' do
      include_examples 'Object custom field values', object_name: 'Organization', klass: Organization
    end

    context 'when resource has no domains' do
      let(:resource) do
        super().merge('domains' => [])
      end

      before do
        imported_organization[:domain] = nil
        imported_organization[:domain_assignment] = false
      end

      it 'adds organizations' do
        process(process_payload)
        expect(Organization.last).to have_attributes(imported_organization)
      end
    end
  end
end
