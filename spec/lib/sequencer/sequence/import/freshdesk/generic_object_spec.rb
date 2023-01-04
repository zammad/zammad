# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Sequencer::Sequence::Import::Freshdesk::GenericObject, db_strategy: 'reset', sequencer: :sequence do
  context 'when importing group list with generic object' do
    let(:resources_payloud) do
      [
        {
          'id'               => 80_000_374_715,
          'name'             => 'QA',
          'description'      => 'Members of the QA team belong to this group',
          'escalate_to'      => nil,
          'unassigned_for'   => nil,
          'business_hour_id' => nil,
          'group_type'       => 'support_agent_group',
          'created_at'       => '2021-04-09T13:23:59Z',
          'updated_at'       => '2021-04-09T13:23:59Z'
        },
        {
          'id'               => 80_000_374_716,
          'name'             => 'Testing',
          'description'      => 'Members of the Testing team belong to this group',
          'escalate_to'      => nil,
          'unassigned_for'   => nil,
          'business_hour_id' => nil,
          'group_type'       => 'support_agent_group',
          'created_at'       => '2021-04-09T13:23:59Z',
          'updated_at'       => '2021-04-09T13:23:59Z'
        }
      ]
    end

    let(:process_payload) do
      {
        import_job:           build_stubbed(:import_job, name: 'Import::Freshdesk', payload: {}),
        dry_run:              false,
        object:               'Group',
        request_params:       {},
        field_map:            {},
        id_map:               {},
        skipped_resource_id:  nil,
        time_entry_available: true,
      }
    end

    before do
      # Mock the groups get request
      stub_request(:get, 'https://yours.freshdesk.com/api/v2/groups?per_page=100').to_return(status: 200, body: JSON.generate(resources_payloud), headers: {})
    end

    it 'add groups' do
      expect { process(process_payload) }.to change(Group, :count).by(2)
    end

    context 'when list request fails' do
      before do
        allow(Sequencer::Unit::Import::Freshdesk::Request).to receive(:handle_error).with(any_args).and_return(true)
        stub_request(:get, 'https://yours.freshdesk.com/api/v2/groups?per_page=100').to_return(status: 400, headers: {})
      end

      it 'check that a failing response do not raise a hard error' do
        expect { process(process_payload) }.not_to change(Group, :count)
      end
    end
  end
end
