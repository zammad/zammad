# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

require 'lib/sequencer/sequence/import/kayako/examples/object_custom_field_values_examples'

RSpec.describe Sequencer::Sequence::Import::Kayako::Case, db_strategy: :reset, sequencer: :sequence do

  context 'when importing cases from Kayako' do

    let(:group)        { create(:group) }
    let(:owner)        { create(:agent, group_ids: [group.id]) }
    let(:organization) { create(:organization) }
    let(:customer)     { create(:customer, organization: organization) }

    let(:resource) do
      {
        'id'              => 9999,
        'legacy_id'       => nil,
        'subject'         => 'Getting comfortable with Kayako: a sample conversation',
        'portal'          => 'SETUP',
        'source_channel'  => {
          'uuid'            => 'e955e374-8324-4637-97a5-763cd4010997',
          'type'            => 'MAIL',
          'character_limit' => nil,
          'resource_type'   => 'channel'
        },
        'requester'       => {
          'id'            => 80_014_400_777,
          'organization'  => {
            'id'            => 80_014_400_111,
            'resource_type' => 'organization'
          },
          'resource_type' => 'user',
        },
        'creator'         => {
          'id'            => 80_014_400_777,
          'resource_type' => 'user',
        },
        'identity'        => {
          'id'            => 80_014_400_777,
          'resource_type' => 'identity_email'
        },
        'assigned_agent'  => {
          'id'            => 80_014_400_475,
          'resource_type' => 'user',
        },
        'assigned_team'   => {
          'id'            => 80_000_374_718,
          'resource_type' => 'team'
        },
        'status'          => {
          'id'            => 2,
          'label'         => 'Open',
          'type'          => 'OPEN',
          'sort_order'    => 2,
          'is_sla_active' => true,
          'is_deleted'    => false,
          'created_at'    => '2021-08-12T11:48:51+00:00',
          'updated_at'    => '2021-08-12T11:48:51+00:00',
          'resource_type' => 'case_status',
        },
        'priority'        => {
          'id'            => 1,
          'label'         => 'Low',
          'level'         => 1,
          'created_at'    => '2021-08-12T11:48:51+00:00',
          'updated_at'    => '2021-08-12T11:48:51+00:00',
          'resource_type' => 'case_priority',
        },
        'type'            => {
          'id'         => 1,
          'label'      => 'Question',
          'type'       => 'QUESTION',
          'created_at' => '2021-08-12T11:48:51+00:00',
          'updated_at' => '2021-08-12T11:48:51+00:00',
        },
        'last_updated_by' => {
          'id'            => 80_000_374_718,
          'resource_type' => 'user',
        },
        'state'           => 'ACTIVE',
        'tags'            => [
          {
            'id'            => 1,
            'name'          => 'example',
            'resource_type' => 'tag'
          },
          {
            'id'            => 2,
            'name'          => 'test',
            'resource_type' => 'tag'
          }
        ],
        'created_at'      => '2018-08-18T12:00:00+00:00',
        'updated_at'      => '2021-08-24T06:30:00+00:00',
        'resource_type'   => 'case',
      }

    end

    let(:id_map) do
      {
        'Organization' => {
          80_014_400_111 => organization.id,
        },
        'User'         => {
          80_014_400_475 => owner.id,
          80_014_400_777 => customer.id,
        },
        'Group'        => {
          80_000_374_718 => group.id,
        },
      }
    end
    let(:process_payload) do
      {
        import_job:       build_stubbed(:import_job, name: 'Import::Kayako', payload: {}),
        dry_run:          false,
        resource:         resource,
        field_map:        {},
        id_map:           id_map,
        default_language: 'en-us',
      }
    end

    let(:posts_response_payload) do
      {
        'data' => [
          {
            'id'             => 99_999,
            'uuid'           => '179a033a-7582-4def-ae57-b8f077eaee5b',
            'client_id'      => '',
            'subject'        => 'Getting comfortable with Kayako: a sample conversation',
            'contents'       => 'Some text conent\n',
            'creator'        => {
              'id'            => 80_014_400_777,
              'resource_type' => 'user'
            },
            'identity'       => {
              'id'            => 80_014_400_777,
              'email'         => customer.email,
              'resource_type' => 'identity_email',
            },
            'source_channel' => {
              'uuid'            => 'e955e374-8324-4637-97a5-763cd4010997',
              'type'            => 'MAIL',
              'character_limit' => nil,
              'account'         => {
                'id'            => 1,
                'resource_type' => 'mailbox'
              },
              'resource_type'   => 'channel'
            },
            'attachments'    => [],
            'original'       => {
              'id'            => 4,
              'uuid'          => '179a033a-7582-4def-ae57-b8f077eaee5b',
              'subject'       => 'Getting comfortable with Kayako: a sample conversation',
              'body_text'     => 'Some text conent\n',
              'body_html'     => '<div dir=\'ltr\'>Some text conent<br></div>',
              'recipients'    => [],
              'fullname'      => customer.fullname,
              'email'         => customer.email,
              'creator'       => {
                'id'            => 80_014_400_777,
                'resource_type' => 'user'
              },
              'identity'      => {
                'id'            => 80_014_400_777,
                'email'         => customer.email,
                'resource_type' => 'identity_email',
              },
              'mailbox'       => {
                'id'            => 1,
                'uuid'          => 'e955e374-8324-4637-97a5-763cd4010997',
                'address'       => 'info@zammad.org',
                'resource_type' => 'mailbox',
              },
              'attachments'   => [],
              'download_all'  => nil,
              'locale'        => nil,
              'response_time' => 0,
              'created_at'    => '2021-08-16T08:19:40+00:00',
              'updated_at'    => '2021-08-16T08:19:40+00:00',
              'resource_type' => 'case_message',
            },
            'is_requester'   => true,
            'created_at'     => '2021-08-16T08:19:40+00:00',
            'updated_at'     => '2021-08-16T08:30:11+00:00',
            'resource_type'  => 'post',
          }
        ]
      }
    end

    let(:imported_ticket) do
      {
        title:                    'Getting comfortable with Kayako: a sample conversation',
        note:                     nil,
        create_article_type_id:   1,
        create_article_sender_id: 2,
        article_count:            1,
        state_id:                 2,
        group_id:                 group.id,
        priority_id:              1,
        owner_id:                 owner.id,
        customer_id:              customer.id,
        organization_id:          organization.id,
        type:                     'Question'
      }
    end

    before do
      # Mock the posts get request (Import::Kayako::Case::Posts).
      stub_request(:get, 'https://yours.kayako.com/api/v1/cases/9999/posts?include=mailbox,message_recipient,channel,attachment,case_message,note,chat_message,identity_email,identity_twitter,identity_facebook,facebook_message,facebook_post,facebook_post_comment,twitter_message,twitter_tweet&limit=100').to_return(status: 200, body: JSON.generate(posts_response_payload), headers: {})
    end

    it 'adds tickets' do
      expect { process(process_payload) }.to change(Ticket, :count).by(1)
    end

    it 'correct attributes for added ticket' do
      process(process_payload)
      expect(Ticket.last).to have_attributes(imported_ticket)
    end

    it 'correct tags for added ticket' do
      process(process_payload)
      expect(Ticket.last.tag_list).to eq(%w[example test])
    end

    it 'adds article' do
      expect { process(process_payload) }.to change(Ticket::Article, :count).by(1)
    end

    it 'correct attributes for added article' do
      process(process_payload)
      expect(Ticket::Article.last).to have_attributes(
        to:   'info@zammad.org',
        body: "<div dir=\"ltr\">Some text conent<br>\n</div>",
      )
    end

    context 'when ticket is imported twice' do
      before do
        process(process_payload)
      end

      it 'updates first article for already existing ticket' do
        expect { process(process_payload) }.not_to change(Ticket::Article, :count)
      end
    end

    context 'when importing without a type' do
      before do
        resource['type'] = nil
        imported_ticket[:type] = nil
      end

      it 'correct attributes for added ticket' do
        process(process_payload)
        expect(Ticket.last).to have_attributes(imported_ticket)
      end
    end

    context "when status is 'PENDING'" do
      before do
        resource['status'] = {
          'id'            => 3,
          'label'         => 'Pending',
          'type'          => 'PENDING',
          'sort_order'    => 3,
          'is_sla_active' => false,
          'is_deleted'    => false,
          'created_at'    => '2021-08-12T11:48:51+00:00',
          'updated_at'    => '2021-08-12T11:48:51+00:00',
        }
        imported_ticket[:state_id] = 3
      end

      it 'correct attributes for added ticket' do
        process(process_payload)
        expect(Ticket.last).to have_attributes(imported_ticket)
      end
    end

    context 'when importing custom fields' do
      include_examples 'Object custom field values', object_name: 'Ticket', klass: Ticket
    end
  end
end
