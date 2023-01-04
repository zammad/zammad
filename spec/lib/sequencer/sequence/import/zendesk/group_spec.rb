# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'zendesk_api'

RSpec.describe Sequencer::Sequence::Import::Zendesk::Group, sequencer: :sequence do

  context 'when importing groups from Zendesk' do

    let(:base_resource) do
      ZendeskAPI::Group.new(
        nil,
        {
          'id'          => 24_165_105,
          'name'        => 'Additional Group',
          'description' => '',
          'default'     => false,
          'created_at'  => '2015-12-04 13:11:59 UTC',
          'updated_at'  => '2015-12-04 13:11:59 UTC'
        }
      )
    end

    let(:process_payload) do
      {
        import_job: build_stubbed(:import_job, name: 'Import::Zendesk', payload: {}),
        dry_run:    false,
        resource:   resource,
        field_map:  {},
      }
    end

    context 'with active group' do

      let(:resource) do
        base_resource.merge('deleted' => false)
      end

      it 'adds groups', :aggregate_failures do
        expect { process(process_payload) }.to change(Group, :count).by(1)
        expect(Group.last).to have_attributes(
          name:   'Additional Group',
          active: true,
        )
      end
    end

    context 'with inactive group' do

      let(:resource) do
        base_resource.merge('deleted' => true)
      end

      it 'adds groups', :aggregate_failures do
        expect { process(process_payload) }.to change(Group, :count).by(1)
        expect(Group.last).to have_attributes(
          name:   'Additional Group',
          active: false,
        )
      end
    end
  end
end
