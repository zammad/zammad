# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe ::Sequencer::Sequence::Import::Freshdesk::ContactField, sequencer: :sequence do

  context 'when tryping to import contact fields from Freshdesk', db_strategy: :reset do

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
          'editable_in_signup'      => false,
          'id'                      => 80_000_776_200,
          'name'                    => 'custom_dropdown',
          'label'                   => 'custom_dropdown',
          'position'                => 16,
          'required_for_agents'     => false,
          'type'                    => 'custom_dropdown',
          'default'                 => false,
          'customers_can_edit'      => true,
          'label_for_customers'     => 'custom_dropdown',
          'required_for_customers'  => false,
          'displayed_for_customers' => true,
          'created_at'              => '2021-04-12T20:19:46Z',
          'updated_at'              => '2021-04-12T20:19:46Z',
          'choices'                 => [ 'First Choice', 'Second Choice']
        }
      end

      it 'adds custom fields' do
        expect { process(process_payload) }.to change(User, :column_names).by(['custom_dropdown'])
      end
    end

    context 'when fields are invalid' do

      let(:resource) do
        {
          'editable_in_signup'      => false,
          'id'                      => 80_000_766_844,
          'name'                    => 'twitter_followers_count',
          'label'                   => 'Twitter Follower Count',
          'position'                => 15,
          'required_for_agents'     => false,
          'type'                    => 'default_twitter_followers_count',
          'default'                 => true,
          'customers_can_edit'      => false,
          'label_for_customers'     => 'Twitter Follower Count',
          'required_for_customers'  => false,
          'displayed_for_customers' => false,
          'created_at'              => '2021-04-09T13:24:02Z',
          'updated_at'              => '2021-04-09T13:24:02Z'
        }
      end

      it 'ignores other fields' do
        expect { process(process_payload) }.not_to change(User, :column_names)
      end
    end
  end
end
