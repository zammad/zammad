# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

require 'lib/sequencer/sequence/import/kayako/examples/object_custom_fields_examples'

RSpec.describe Sequencer::Sequence::Import::Kayako::OrganizationField, sequencer: :sequence do

  context 'when trying to import ticket fields from Kayako', db_strategy: :reset do
    include_examples 'Object custom fields', klass: Organization

    context 'when checking screens configuration' do
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

      let(:resource) do
        {
          'id'                        => 80_000_387_409,
          'fielduuid'                 => '82e5393b-e036-45d1-beb9-46f96ebd697a',
          'title'                     => 'Textfield',
          'type'                      => 'TEXT',
          'key'                       => 'custom_textfield',
          'is_visible_to_customers'   => false,
          'is_required_for_agents'    => true,
          'is_customer_editable'      => false,
          'is_required_for_customers' => false,
          'regular_expression'        => nil,
          'sort_order'                => 1,
          'is_enabled'                => true,
          'options'                   => [],
          'created_at'                => '2021-08-16T19:34:35+00:00',
          'updated_at'                => '2021-08-16T19:34:35+00:00',
        }
      end

      it 'sets create, edit and view screens for Organization fields' do
        process(process_payload)
        expect(ObjectManager::Attribute.get(object: 'Organization', name: 'custom_textfield').screens).to eq(
          'create' => { '-all-' => { 'shown' => true } },
          'edit'   => { '-all-' => { 'shown' => true } },
          'view'   => { '-all-' => { 'shown' => true } },
        )
      end
    end
  end
end
