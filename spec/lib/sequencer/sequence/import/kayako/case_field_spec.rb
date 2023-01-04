# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

require 'lib/sequencer/sequence/import/kayako/examples/object_custom_fields_examples'

RSpec.describe Sequencer::Sequence::Import::Kayako::CaseField, sequencer: :sequence do

  context 'when trying to import ticket fields from Kayako', db_strategy: :reset do
    let(:imported_type_options) do
      {
        'Question' => 'Question',
        'Task'     => 'Task',
        'Problem'  => 'Problem',
        'Incident' => 'Incident',
      }
    end

    include_examples 'Object custom fields', klass: Ticket

    context 'when importing system fields' do
      let(:resource) do
        {
          'id'                        => 80_000_387_409,
          'fielduuid'                 => 'cad5295c-495a-4605-8eda-861d4a19d6f2',
          'title'                     => 'Type',
          'type'                      => 'TYPE',
          'key'                       => 'type',
          'is_required_for_agents'    => false,
          'is_required_on_resolution' => false,
          'is_visible_to_customers'   => false,
          'is_customer_editable'      => false,
          'is_required_for_customers' => false,
          'regular_expression'        => nil,
          'sort_order'                => 5,
          'is_enabled'                => true,
          'is_system'                 => true,
          'options'                   => [],
          'created_at'                => '2021-08-12T11:48:51+00:00',
          'updated_at'                => '2021-08-12T11:48:51+00:00',
        }
      end

      it "activate the already existing ticket 'type' field" do
        expect { process(process_payload) }.to change { ObjectManager::Attribute.get(object: 'Ticket', name: 'type').active }.from(false).to(true)
      end

      it "import the fixed option list for the ticket 'type' field" do
        process(process_payload)
        expect(ObjectManager::Attribute.get(object: 'Ticket', name: 'type').data_option[:options]).to include(imported_type_options)
      end
    end
  end
end
