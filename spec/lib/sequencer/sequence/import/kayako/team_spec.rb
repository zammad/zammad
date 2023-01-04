# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Sequencer::Sequence::Import::Kayako::Team, sequencer: :sequence do

  context 'when importing teams from Kayako' do

    let(:resource) do
      {
        'id'            => 80_000_374_715,
        'legacy_id'     => nil,
        'title'         => 'Support',
        'businesshour'  => {
          'id'            => 1,
          'resource_type' => 'business_hour'
        },
        'member_count'  => 0,
        'created_at'    => '2021-08-16T13:42:26+00:00',
        'updated_at'    => '2021-08-16T13:42:26+00:00',
        'resource_type' => 'team',
      }
    end

    let(:process_payload) do
      {
        import_job: build_stubbed(:import_job, name: 'Import::Kayako', payload: {}),
        dry_run:    false,
        resource:   resource,
        field_map:  {},
        id_map:     {},
      }
    end

    it 'adds groups' do
      expect { process(process_payload) }.to change(Group, :count).by(1)
    end

    it 'check added group data' do
      process(process_payload)
      expect(Group.last).to have_attributes(
        name:   'Support',
        active: true,
      )
    end
  end
end
