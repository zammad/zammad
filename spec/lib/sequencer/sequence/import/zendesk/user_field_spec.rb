# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'zendesk_api'

RSpec.describe Sequencer::Sequence::Import::Zendesk::UserField, sequencer: :sequence do

  context 'when trying to import user fields from Zendesk', db_strategy: :reset do

    let(:process_payload) do
      {
        import_job: build_stubbed(:import_job, name: 'Import::Zendesk', payload: {}),
        dry_run:    false,
        resource:   resource,
        field_map:  {},
      }
    end

    let(:resource) do
      ZendeskAPI::UserField.new(
        nil,
        {
          'id'                    => 206_315,
          'type'                  => 'text',
          'key'                   => 'lieblingstier',
          'title'                 => 'Lieblingstier',
          'description'           => "Hund,
           Katze oder Maus?",
          'raw_title'             => 'Lieblingstier',
          'raw_description'       => "Hund,
           Katze oder Maus?",
          'position'              => 0,
          'active'                => true,
          'system'                => false,
          'regexp_for_validation' => nil,
          'created_at'            => '2015-12-04 11:05:45 UTC',
          'updated_at'            => '2015-12-04 11:05:45 UTC'
        }
      )
    end

    it 'adds user fields' do
      expect { process(process_payload) }.to change(User, :column_names).by(['lieblingstier'])
    end
  end
end
