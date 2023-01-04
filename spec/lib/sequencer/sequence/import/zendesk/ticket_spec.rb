# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'zendesk_api'

RSpec.describe Sequencer::Sequence::Import::Zendesk::Ticket, db_strategy: :reset, sequencer: :sequence do

  context 'when importing tickets from Zendesk' do

    let(:group) { create(:group) }

    let(:owner) { create(:agent, group_ids: [group.id]) }

    let(:customer) { create(:customer) }

    let(:resource) do
      ZendeskAPI::Ticket.new(
        nil,
        {
          'id'                    => 2,
          'external_id'           => nil,
          'via'                   => {
            'channel' => 'email',
            'source'  => {
              'from' => {
                'address' => 'john.doe@example.com',
                'name'    => 'John Doe'
              },
              'to'   => {
                'name'    => 'Zendesk',
                'address' => 'zendesk-user@example.com'
              },
              'rel'  => nil
            }
          },
          'created_at'            => '2015-07-19 22:44:20 UTC',
          'updated_at'            => '2016-05-19 14:00:42 UTC',
          'type'                  => 'question',
          'subject'               => 'test',
          'raw_subject'           => 'test',
          'description'           => 'test email',
          'priority'              => 'urgent',
          'status'                => 'pending',
          'recipient'             => 'zendesk-user@example.com',
          'requester_id'          => 1_202_726_611,
          'submitter_id'          => 1_147_801_812,
          'assignee_id'           => 1_150_734_731,
          'organization_id'       => 154_755_561,
          'group_id'              => 24_554_931,
          'collaborator_ids'      => [],
          'follower_ids'          => [],
          'email_cc_ids'          => [],
          'forum_topic_id'        => nil,
          'problem_id'            => nil,
          'has_incidents'         => false,
          'is_public'             => true,
          'due_at'                => nil,
          'tags'                  => %w[
            anothertag
            import
            key2
            newtag
            otrs
            zammad
          ],
          'custom_fields'         => [
            { 'id'    => 1001,
              'value' => 'key_1' },
            { 'id'    => 1002,
              'value' => true },
            { 'id'    => 1003,
              'value' => %w[key_1 key_2] },
          ],
          'satisfaction_rating'   => nil,
          'sharing_agreement_ids' => [],
          'followup_ids'          => [],
          'brand_id'              => 670_701,
          'allow_channelback'     => false,
          'allow_attachments'     => true,
          'generated_timestamp'   => 1_463_666_442
        }
      )
    end

    let(:group_map) do
      {
        24_554_931 => group.id,
      }
    end

    let(:user_map) do
      {
        1_150_734_731 => owner.id,
        1_202_726_611 => customer.id,
      }
    end

    let(:organization_map) do
      {}
    end

    let(:ticket_field_map) do
      {
        1001 => 'custom_dropdown',
        1002 => 'custom_checkbox',
        1003 => 'custom_multiselect',
      }
    end

    let(:process_payload) do
      {
        import_job:       build_stubbed(:import_job, name: 'Import::Zendesk', payload: {}),
        dry_run:          false,
        resource:         resource,
        group_map:        group_map,
        user_map:         user_map,
        organization_map: organization_map,
        ticket_field_map: ticket_field_map,
        field_map:        {},
      }
    end

    let(:imported_ticket) do
      {
        title:                    'test',
        note:                     nil,
        create_article_type_id:   1,
        create_article_sender_id: 2,
        article_count:            nil,
        state_id:                 3,
        group_id:                 group.id,
        priority_id:              3,
        owner_id:                 owner.id,
        customer_id:              customer.id,
        type:                     'question',
        custom_dropdown:          'key_1',
        custom_checkbox:          true,
        custom_multiselect:       %w[key_1 key_2],
      }
    end

    before do
      create(:object_manager_attribute_select, object_name: 'Ticket', name: 'custom_dropdown')
      create(:object_manager_attribute_boolean, object_name: 'Ticket', name: 'custom_checkbox')
      create(:object_manager_attribute_multiselect, object_name: 'Ticket', name: 'custom_multiselect')
      ObjectManager::Attribute.migration_execute

      # We only want to test here the Ticket API, so disable other modules in the sequence
      #   that make their own HTTP requests.
      custom_sequence = described_class.sequence.dup
      custom_sequence.delete('Import::Zendesk::Ticket::Comments')
      custom_sequence.delete('Import::Zendesk::Ticket::Tags')

      allow(described_class).to receive(:sequence) { custom_sequence }

    end

    context 'with email ticket' do
      it 'imports user correctly (increased ticket count)' do
        expect { process(process_payload) }.to change(Ticket, :count).by(1)
      end

      it 'imports ticket data correctly' do
        process(process_payload)
        expect(Ticket.last).to have_attributes(imported_ticket)
      end
    end
  end
end
