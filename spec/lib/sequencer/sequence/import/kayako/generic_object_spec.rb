# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Sequencer::Sequence::Import::Kayako::GenericObject, db_strategy: :reset, sequencer: :sequence do
  context 'when importing group list with generic object' do
    let(:resources_payloud) do
      {
        'data' => [
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
          },
          {
            'id'            => 80_000_374_716,
            'legacy_id'     => nil,
            'title'         => 'Sales',
            'businesshour'  => {
              'id'            => 1,
              'resource_type' => 'business_hour'
            },
            'member_count'  => 0,
            'created_at'    => '2021-08-16T13:42:26+00:00',
            'updated_at'    => '2021-08-16T13:42:26+00:00',
            'resource_type' => 'team',
          }
        ]
      }
    end

    let(:process_payload) do
      {
        import_job:       build_stubbed(:import_job, name: 'Import::Kayako', payload: {}),
        dry_run:          false,
        object:           'Team',
        request_params:   {},
        field_map:        {},
        id_map:           {},
        default_language: 'en-us'
      }
    end

    before do
      # Mock the groups get request
      stub_request(:get, 'https://yours.kayako.com/api/v1/teams?limit=100').to_return(status: 200, body: JSON.generate(resources_payloud), headers: {})
    end

    it 'add groups' do
      expect { process(process_payload) }.to change(Group, :count).by(2)
    end

    context 'when list request fails' do
      before do
        allow(Sequencer::Unit::Import::Kayako::Request).to receive(:handle_error).with(any_args).and_return(true)
        stub_request(:get, 'https://yours.kayako.com/api/v1/teams?limit=100').to_return(status: 400, headers: {})
      end

      it 'check that a failing response do not raise a hard error' do
        expect { process(process_payload) }.not_to change(Group, :count)
      end
    end
  end
end
