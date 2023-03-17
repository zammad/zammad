# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Sequencer::Sequence::Import::Kayako::Post, sequencer: :sequence do

  context 'when importing posts from Kayako' do

    let(:user)     { create(:user) }
    let(:customer) { create(:customer) }
    let(:ticket)   { create(:ticket) }

    let(:resource) do
      {
        'id'             => 99_999,
        'uuid'           => '179a033a-7582-4def-ae57-b8f077eaee5b',
        'client_id'      => '',
        'subject'        => 'Getting comfortable with Kayako: a sample conversation',
        'contents'       => "[img src=\"https://yours.kayako.com/media/url/UB6tba5kStQ7pL1i247kJ2blopDsywfn\" class=\"fr-fic fr-dii\" style=\"width: 127px; height: 96.3263px;\" width=\"127\" height=\"96.3263\"]\n\nA Test with a inline image.\n",
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
        'attachments'    => [
          {
            'id'            => 1,
            'name'          => 'example.log',
            'size'          => 1909,
            'width'         => 0,
            'height'        => 0,
            'type'          => 'text/plain',
            'content_id'    => nil,
            'alt'           => nil,
            'url'           => 'https://yours.kayako.com/api/v1/cases/9999/notes/99999/attachments/2/url',
            'url_download'  => 'https://yours.kayako.com/api/v1/cases/9999/notes/99999/attachments/2/download',
            'thumbnails'    => [],
            'created_at'    => '2021-08-16T08:43:46+00:00',
            'resource_type' => 'attachment',
          }
        ],
        'original'       => {
          'id'            => 4,
          'uuid'          => '179a033a-7582-4def-ae57-b8f077eaee5b',
          'subject'       => 'Getting comfortable with Kayako: a sample conversation',
          'body_text'     => "[img src=\"https://yours.kayako.com/media/url/UB6tba5kStQ7pL1i247kJ2blopDsywfn\" class=\"fr-fic fr-dii\" style=\"width: 127px; height: 96.3263px;\" width=\"127\" height=\"96.3263\"]\n\nA Test with a inline image.\n",
          'body_html'     => '<img src="https://yours.kayako.com/media/url/UB6tba5kStQ7pL1i247kJ2blopDsywfn" class="fr-fic fr-dii" style="width: 127px; height: 96.3263px;" width="127" height="96.3263"><br><br>A Test with a inline image.<br>',
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
    end
    let(:used_urls) do
      [
        'https://yours.kayako.com/media/url/UB6tba5kStQ7pL1i247kJ2blopDsywfn',
        'https://yours.kayako.com/api/v1/cases/9999/notes/99999/attachments/2/download'
      ]
    end

    let(:id_map) do
      {
        'Ticket' => {
          1001 => ticket.id,
        },
        'User'   => {
          80_014_400_745 => user.id,
          80_014_400_777 => customer.id,
        }
      }
    end
    let(:process_payload) do
      {
        import_job:       build_stubbed(:import_job, name: 'Import::Kayako', payload: {}),
        dry_run:          false,
        resource:         resource,
        field_map:        {},
        id_map:           id_map,
        instance:         ticket,
        default_language: 'en-us',
      }
    end

    let(:imported_ticket_article_attachment) do
      {
        filename:    'example.log',
        size:        '3',
        preferences: {
          'Content-Type': 'text/plain'
        }
      }
    end

    before do
      # Mock the attachment and inline image download requests.
      used_urls.each do |used_url|
        stub_request(:get, used_url).to_return(status: 200, body: '123', headers: {})
      end
    end

    it 'adds article with inline image' do
      expect { process(process_payload) }.to change(Ticket::Article, :count).by(1)
    end

    it 'correct attributes for added article' do
      process(process_payload)
      expect(Ticket::Article.last).to have_attributes(
        to:   'info@zammad.org',
        body: "\n\n<img src=\"data:image/png;base64,MTIz\" style=\"width: 127px; height: 96.3263px;width:127px;height:96.3263px;\"><br><br>A Test with a inline image.<br>\n\n",
      )
    end

    it 'updates already existing article' do
      expect do
        process(process_payload)
        process(process_payload)
      end.to change(Ticket::Article, :count).by(1)
    end

    it 'adds correct number of attachments' do
      process(process_payload)
      expect(Ticket::Article.last.attachments.size).to eq 1
    end

    it 'adds attachment content' do
      process(process_payload)
      expect(Ticket::Article.last.attachments.last).to have_attributes(imported_ticket_article_attachment)
    end
  end
end
