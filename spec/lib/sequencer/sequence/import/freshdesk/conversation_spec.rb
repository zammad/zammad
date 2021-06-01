# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe ::Sequencer::Sequence::Import::Freshdesk::Conversation, sequencer: :sequence do

  context 'when importing conversations from Freshdesk' do

    let(:resource) do
      {
        'body' => "<div style=\"font-family:-apple-system, BlinkMacSystemFont, Segoe UI, Roboto, Helvetica Neue, Arial, sans-serif; font-size:14px\">\n<div dir=\"ltr\">Let's see if inline images work in a subsequent article:</div>\n<div dir=\"ltr\"><img src=\"https://eucattachment.freshdesk.com/inline/attachment?token=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpZCI6ODAwMTIyMjY4NTMsImRvbWFpbiI6InphbW1hZC5mcmVzaGRlc2suY29tIiwiYWNjb3VudF9pZCI6MTg5MDU2MH0.705lNehzm--aO36CGFg0SW73j0NG3UWcRcN1_DXgtwc\" style=\"width: auto\" class=\"fr-fil fr-dib\" data-id=\"80012226853\"></div>\n</div>", 'body_text' => "Let's see if inline images work in a subsequent article:",
        'id' => 80_027_218_656,
        'incoming' => false,
        'private' => true,
        'user_id' => 80_014_400_475,
        'support_email' => nil,
        'source' => 2,
        'category' => 2,
        'to_emails' => ['info@zammad.org'],
        'from_email' => nil,
        'cc_emails' => [],
        'bcc_emails' => nil,
        'email_failure_count' => nil,
        'outgoing_failures' => nil,
        'created_at' => '2021-05-14T12:30:19Z',
        'updated_at' => '2021-05-14T12:30:19Z',
        'attachments' => [
          {
            'id'             => 80_012_226_885,
            'name'           => 'standalone_attachment.png',
            'content_type'   => 'image/png',
            'size'           => 11_447,
            'created_at'     => '2021-05-14T12:30:16Z',
            'updated_at'     => '2021-05-14T12:30:19Z',
            'attachment_url' => 'https://s3.eu-central-1.amazonaws.com/euc-cdn.freshdesk.com/data/helpdesk/attachments/production/80012226885/original/standalone_attachment.png?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAS6FNSMY2RG7BSUFP%2F20210514%2Feu-central-1%2Fs3%2Faws4_request&X-Amz-Date=20210514T123300Z&X-Amz-Expires=300&X-Amz-SignedHeaders=host&X-Amz-Signature=750988d37a6f2f43830bfd19c895517aa051aa13b4ab26a1333369d414fef0be',
            'thumb_url'      => 'https://s3.eu-central-1.amazonaws.com/euc-cdn.freshdesk.com/data/helpdesk/attachments/production/80012226885/thumb/standalone_attachment.png?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAS6FNSMY2RG7BSUFP%2F20210514%2Feu-central-1%2Fs3%2Faws4_request&X-Amz-Date=20210514T123300Z&X-Amz-Expires=300&X-Amz-SignedHeaders=host&X-Amz-Signature=40b5fe1d7d418bcbd1e639b273a1038c7a73781c16d9881c2f31a11c6bebfdf9'
          }
        ],
        'auto_response' => false,
        'ticket_id' => 1001,
        'source_additional_info' => nil
      }
    end
    let(:used_urls) do
      [
        'https://eucattachment.freshdesk.com/inline/attachment?token=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpZCI6ODAwMTIyMjY4NTMsImRvbWFpbiI6InphbW1hZC5mcmVzaGRlc2suY29tIiwiYWNjb3VudF9pZCI6MTg5MDU2MH0.705lNehzm--aO36CGFg0SW73j0NG3UWcRcN1_DXgtwc',
        'https://s3.eu-central-1.amazonaws.com/euc-cdn.freshdesk.com/data/helpdesk/attachments/production/80012226885/original/standalone_attachment.png?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAS6FNSMY2RG7BSUFP%2F20210514%2Feu-central-1%2Fs3%2Faws4_request&X-Amz-Date=20210514T123300Z&X-Amz-Expires=300&X-Amz-SignedHeaders=host&X-Amz-Signature=750988d37a6f2f43830bfd19c895517aa051aa13b4ab26a1333369d414fef0be',
      ]
    end

    let(:ticket) { create :ticket }
    let(:id_map) do
      {
        'Ticket' => {
          1001 => ticket.id,
        },
        'User'   => {
          80_014_400_475 => 1,
        }
      }
    end
    let(:process_payload) do
      {
        import_job: build_stubbed(:import_job, name: 'Import::Freshdesk', payload: {}),
        dry_run:    false,
        resource:   resource,
        field_map:  {},
        id_map:     id_map,
      }
    end

    before do
      # Mock the attachment and inline image download requests.
      used_urls.each do |used_url|
        stub_request(:get, used_url).to_return(status: 200, body: '123', headers: {})
      end
    end

    it 'adds article with inline image' do # rubocop:disable RSpec/MultipleExpectations
      expect { process(process_payload) }.to change(Ticket::Article, :count).by(1)
      expect(Ticket::Article.last).to have_attributes(
        to:   'info@zammad.org',
        body: "\n<div>\n<div dir=\"ltr\">Let's see if inline images work in a subsequent article:</div>\n<div dir=\"ltr\"><img src=\"data:image/png;base64,MTIz\" style=\"width: auto;\"></div>\n</div>\n",
      )
    end

    it 'adds correct number of attachments' do
      process(process_payload)
      expect(Ticket::Article.last.attachments.size).to eq 1
    end

    it 'adds attachment content' do # rubocop:disable RSpec/ExampleLength
      process(process_payload)
      expect(Ticket::Article.last.attachments.last).to have_attributes(
        'filename'    => 'standalone_attachment.png',
        'size'        => '3',
        'preferences' => {
          'Content-Type' => 'image/png',
          'resizable'    => false,
        }
      )
    end
  end
end
