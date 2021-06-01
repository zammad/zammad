# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe ::Sequencer::Sequence::Import::Freshdesk::CompanyField, sequencer: :sequence do

  context 'when trying to import company fields from Freshdesk', db_strategy: :reset do

    let(:process_payload) do
      {
        import_job: build_stubbed(:import_job, name: 'Import::Freshdesk', payload: {}),
        dry_run:    false,
        resource:   resource,
        field_map:  {},
        id_map:     {},
      }
    end

    # Other field types are checked in ticket_field_spec.rb.
    context 'when fields are valid' do
      let(:resource) do
        {
          'id'                  => 80_000_387_409,
          'name'                => 'custom_dropdown',
          'label'               => 'custom_dropdown',
          'position'            => 9,
          'required_for_agents' => false,
          'type'                => 'custom_dropdown',
          'default'             => false,
          'created_at'          => '2021-04-12T20:24:41Z',
          'updated_at'          => '2021-04-12T20:24:41Z',
          'choices'             => [
            'First Choice',
            'Second Choice',
          ],
        }
      end

      it 'adds custom fields' do
        expect { process(process_payload) }.to change(Organization, :column_names).by(['custom_dropdown'])
      end
    end

    context 'when fields are invalid' do

      let(:resource) do
        {
          'id'                  => 80_000_382_712,
          'name'                => 'name',
          'label'               => 'Company Name',
          'position'            => 1,
          'required_for_agents' => true,
          'type'                => 'default_name',
          'default'             => true,
          'created_at'          => '2021-04-09T13:23:59Z',
          'updated_at'          => '2021-04-09T13:23:59Z'
        }
      end

      it 'ignores other fields' do
        expect { process(process_payload) }.not_to change(Organization, :column_names)
      end
    end
  end
end
