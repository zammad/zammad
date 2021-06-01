# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe ::Sequencer::Sequence::Import::Freshdesk::Group, sequencer: :sequence do

  context 'when importing groups from Freshdesk' do

    let(:resource) do
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
      }
    end

    let(:process_payload) do
      {
        import_job: build_stubbed(:import_job, name: 'Import::Freshdesk', payload: {}),
        dry_run:    false,
        resource:   resource,
        field_map:  {},
        id_map:     {},
      }
    end

    it 'adds groups' do # rubocop:disable RSpec/MultipleExpectations
      expect { process(process_payload) }.to change(Group, :count).by(1)
      expect(Group.last).to have_attributes(
        name:   'QA',
        active: true,
      )
    end
  end
end
