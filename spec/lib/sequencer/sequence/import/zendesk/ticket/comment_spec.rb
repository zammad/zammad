# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'zendesk_api'

RSpec.describe Sequencer::Sequence::Import::Zendesk::Ticket::Comment, db_strategy: :reset, required_envs: %w[IMPORT_ZENDESK_ENDPOINT], sequencer: :sequence do

  let(:hostname) { URI.parse(ENV['IMPORT_ZENDESK_ENDPOINT']).hostname }

  context 'when importing ticket comments from Zendesk' do

    let(:customer) { create(:customer) }

    let(:ticket) { create(:ticket) }

    let(:inline_image_url) { "https://#{hostname}/attachments/token/khRQTQjm8ODhA0FjbS39i4xOb/?name=1a3496b9-53d9-494d-bbb0-e1d2e22074f8.jpeg" }

    let(:resource) do
      ZendeskAPI::Ticket::Comment.new(
        nil,
        {
          'id'          => 31_964_468_581,
          'type'        => 'Comment',
          'author_id'   => 1_150_734_731,
          'html_body'   => "<div class=\"zd-comment\" dir=\"auto\"><p dir=\"auto\">This is the latest comment for this ticket. You also changed the ticket status to Pending.</p><span style=\"opacity: 1;\"><img src=\"#{inline_image_url}\"></span><a href=\"/agent/tickets/1\" rel=\"ticket\">#1</a></p></div>",
          'public'      => true,
          'attachments' => [
            {
              'id'                 => 1_282_310_719,
              'file_name'          => '1a3496b9-53d9-494d-bbb0-e1d2e22074f8.jpeg',
              'content_url'        => "https://#{hostname}/attachments/token/khRQTQjm8ODhA0FjbS39i4xOb/?name=1a3496b9-53d9-494d-bbb0-e1d2e22074f8.jpeg",
              'mapped_content_url' => "https://#{hostname}/attachments/token/khRQTQjm8ODhA0FjbS39i4xOb/?name=1a3496b9-53d9-494d-bbb0-e1d2e22074f8.jpeg",
              'content_type'       => 'image/jpeg',
              'size'               => 164_934,
              'width'              => 1600,
              'height'             => 1200,
              'inline'             => false,
              'deleted'            => false,
              'thumbnails'         => []
            }
          ],
          'audit_id'    => 31_964_468_571,
          'via'         => {
            'channel' => 'email',
            'source'  => {
              'from' => {
                'address'             => 'john.doe@example.com',
                'name'                => 'John Doe',
                'original_recipients' => [
                  'zendesk@example.com'
                ]
              },
              'to'   => {
                'name'    => 'Znuny',
                'address' => 'zendesk@example.com'
              },
              'rel'  => nil
            },
          },
          'created_at'  => '2018-09-28T12:00:00Z',
          'metadata'    => {
            'system' => {},
            'custom' => {}
          }
        }
      )
    end

    let(:user_map) do
      {
        1_150_734_731 => customer.id,
      }
    end

    let(:process_payload) do
      {
        import_job: build_stubbed(:import_job, name: 'Import::Zendesk', payload: {}),
        dry_run:    false,
        instance:   ticket,
        resource:   resource,
        user_map:   user_map,
        field_map:  {},
      }
    end

    let(:imported_article) do
      {
        from:       'john.doe@example.com',
        to:         'zendesk@example.com',
        body:       "\n<div dir=\"auto\">\n<p dir=\"auto\">This is the latest comment for this ticket. You also changed the ticket status to Pending.</p>\n<span><img src=\"data:image/png;base64,MTIz\"></span><a href=\"/#ticket/zoom/1\" rel=\"ticket\">#1</a>\n</div>\n",
        created_at: Time.zone.parse('2018-09-28T12:00:00Z'),
        updated_at: Time.zone.parse('2018-09-28T12:00:00Z'),
      }
    end

    let(:imported_attachment) do
      {
        'filename'    => '1a3496b9-53d9-494d-bbb0-e1d2e22074f8.jpeg',
        'size'        => '3',
        'preferences' => {
          'Content-Type'    => 'image/jpeg',
          'resizable'       => false,
          'content_preview' => true,
        }
      }
    end

    before do
      stub_request(:get, "https://#{hostname}/attachments/token/khRQTQjm8ODhA0FjbS39i4xOb/?name=1a3496b9-53d9-494d-bbb0-e1d2e22074f8.jpeg").to_return(status: 200, body: '123', headers: {})
    end

    context 'with an email article' do
      it 'imports article correctly' do
        expect { process(process_payload) }.to change(Ticket::Article, :count).by(1)
      end

      it 'imports ticket data correctly' do
        process(process_payload)
        expect(Ticket::Article.last).to have_attributes(imported_article)
      end

      it 'adds correct number of attachments' do
        process(process_payload)
        expect(Ticket::Article.last.attachments.size).to eq 1
      end

      it 'adds attachment content' do
        process(process_payload)
        expect(Ticket::Article.last.attachments.last).to have_attributes(imported_attachment)
      end
    end

    context 'when attachment request has an error' do
      before do
        allow_any_instance_of(Sequencer::Unit::Import::Zendesk::Ticket::Comment::Attachment::Request).to receive(:sleep)
        stub_request(:get, "https://#{hostname}/attachments/token/khRQTQjm8ODhA0FjbS39i4xOb/?name=1a3496b9-53d9-494d-bbb0-e1d2e22074f8.jpeg").to_return(status: 503, headers: {}).then.to_return(status: 200, body: '123', headers: {})
      end

      it 'adds attachment content after one request error' do
        process(process_payload)
        expect(Ticket::Article.last.attachments.last).to have_attributes(imported_attachment)
      end
    end
  end
end
