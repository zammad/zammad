# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Ticket Article Attachments', type: :request, authenticated_as: -> { agent } do

  let(:group) { create(:group) }

  let(:agent) do
    create(:agent, groups: [Group.lookup(name: 'Users'), group])
  end

  describe 'request handling' do
    context 'with attachment urls' do
      let(:ticket1) { create(:ticket, group: group) }
      let(:article1) { create(:ticket_article, ticket: ticket1) }
      let(:ticket2)  { create(:ticket, group: group) }
      let(:article2) { create(:ticket_article, ticket: ticket2) }

      let(:store_file_content_type) { 'text/plain' }
      let(:store_file_content) { 'some content' }
      let(:store_file_name)    { 'some_file.txt' }
      let!(:store_file) do
        create(:store,
               object:      'Ticket::Article',
               o_id:        article1.id,
               data:        store_file_content,
               filename:    store_file_name,
               preferences: {
                 'Content-Type' => store_file_content_type,
               })
      end

      context 'with one article attachment' do
        it 'does test different attachment urls' do
          get "/api/v1/ticket_attachment/#{ticket1.id}/#{article1.id}/#{store_file.id}", params: {}
          expect(response).to have_http_status(:ok)
          expect('some content').to eq(response.body)

          get "/api/v1/ticket_attachment/#{ticket1.id}/#{article2.id}/#{store_file.id}", params: {}
          expect(response).to have_http_status(:forbidden)
          expect(response.body).to match(%r{403: Forbidden})
        end
      end

      context 'with attachment from merged ticket' do
        before do
          ticket1.merge_to(
            ticket_id: ticket2.id,
            user_id:   1,
          )
        end

        it 'does test attachment url after ticket merge' do
          get "/api/v1/ticket_attachment/#{ticket2.id}/#{article1.id}/#{store_file.id}", params: {}
          expect(response).to have_http_status(:ok)
          expect('some content').to eq(response.body)

          get "/api/v1/ticket_attachment/#{ticket2.id}/#{article2.id}/#{store_file.id}", params: {}
          expect(response).to have_http_status(:forbidden)
          expect(response.body).to match(%r{403: Forbidden})

          # allow access via merged ticket id also
          get "/api/v1/ticket_attachment/#{ticket1.id}/#{article1.id}/#{store_file.id}", params: {}
          expect(response).to have_http_status(:ok)
          expect('some content').to eq(response.body)

          get "/api/v1/ticket_attachment/#{ticket1.id}/#{article2.id}/#{store_file.id}", params: {}
          expect(response).to have_http_status(:forbidden)
          expect(response.body).to match(%r{403: Forbidden})
        end
      end

      context 'with different file content types' do
        context 'without allowed inline file content type' do
          it 'disposition can not be inline' do
            get "/api/v1/ticket_attachment/#{ticket1.id}/#{article1.id}/#{store_file.id}?disposition=inline", params: {}
            expect(response.headers['Content-Disposition']).to include('attachment')
          end

          it 'content-type is correct' do
            get "/api/v1/ticket_attachment/#{ticket1.id}/#{article1.id}/#{store_file.id}?disposition=inline", params: {}
            expect(response.headers['Content-Type']).to include('text/plain')
          end
        end

        context 'with binary file content type' do
          let(:store_file_content_type) { 'image/svg+xml' }

          it 'disposition can not be inline' do
            get "/api/v1/ticket_attachment/#{ticket1.id}/#{article1.id}/#{store_file.id}?disposition=inline", params: {}
            expect(response.headers['Content-Disposition']).to include('attachment')
          end

          it 'content-type was forced to active storage binary content type' do
            get "/api/v1/ticket_attachment/#{ticket1.id}/#{article1.id}/#{store_file.id}?disposition=inline", params: {}
            expect(response.headers['Content-Type']).to include('application/octet-stream')
          end
        end

        context 'with allowed inline file content type' do
          let(:store_file_content_type) { 'application/pdf' }

          it 'disposition is inline' do
            get "/api/v1/ticket_attachment/#{ticket1.id}/#{article1.id}/#{store_file.id}?disposition=inline", params: {}
            expect(response.headers['Content-Disposition']).to include('inline')
          end
        end

        context 'with calendar preview' do
          let(:store_file_content) do
            Rails.root.join('spec/fixtures/files/calendar/basic.ics').read
          end
          let(:store_file_name) { 'basic.ics' }
          let(:store_file_content_type) { 'text/calendar' }

          let(:expected_event) do
            {
              'title'       => 'Test Summary',
              'location'    => 'https://us.zoom.us/j/example?pwd=test',
              'start_date'  => '2021-07-27T10:30:00.000+02:00',
              'end_date'    => '2021-07-27T12:00:00.000+02:00',
              'attendees'   => ['M.bob@example.com', 'J.doe@example.com'],
              'organizer'   => 'f.sample@example.com',
              'description' => 'Test description'
            }
          end

          it 'renders a parsed calender data' do
            get "/api/v1/ticket_attachment/#{ticket1.id}/#{article1.id}/#{store_file.id}?view=preview&type=calendar", params: {}

            expect(response).to have_http_status(:ok)
            expect(json_response).to be_a(Hash)
            expect(json_response['filename']).to eq store_file_name
            expect(json_response['events'].first).to include(expected_event)
          end
        end
      end
    end

    context 'when attachment actions are used' do
      it 'does test attachments for split' do
        email_file_path  = Rails.root.join('test/data/mail/mail024.box')
        email_raw_string = File.read(email_file_path)
        ticket_p, article_p, _user_p = Channel::EmailParser.new.process({}, email_raw_string)

        get '/api/v1/ticket_split', params: { form_id: '1234-2', ticket_id: ticket_p.id, article_id: article_p.id }, as: :json
        expect(response).to have_http_status(:ok)
        expect(json_response['assets']).to be_truthy
        expect(json_response['attachments']).to be_a(Array)
        expect(json_response['attachments'].count).to eq(1)
        expect(json_response['attachments'][0]['filename']).to eq('rulesets-report.csv')

      end

      it 'does test attachments for forward' do
        email_file_path  = Rails.root.join('test/data/mail/mail008.box')
        email_raw_string = File.read(email_file_path)
        _ticket_p, article_p, _user_p = Channel::EmailParser.new.process({}, email_raw_string)

        post "/api/v1/ticket_attachment_upload_clone_by_article/#{article_p.id}", params: {}, as: :json
        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response).to be_a(Hash)
        expect(json_response['error']).to eq("Need 'form_id' to add attachments to new form.")

        post "/api/v1/ticket_attachment_upload_clone_by_article/#{article_p.id}", params: { form_id: '1234-1' }, as: :json
        expect(response).to have_http_status(:ok)
        expect(json_response['attachments']).to be_a(Array)
        expect(json_response['attachments']).to be_blank

        email_file_path  = Rails.root.join('test/data/mail/mail024.box')
        email_raw_string = File.read(email_file_path)
        _ticket_p, article_p, _user_p = Channel::EmailParser.new.process({}, email_raw_string)

        post "/api/v1/ticket_attachment_upload_clone_by_article/#{article_p.id}", params: { form_id: '1234-2' }, as: :json
        expect(response).to have_http_status(:ok)
        expect(json_response['attachments']).to be_a(Array)
        expect(json_response['attachments'].count).to eq(1)
        expect(json_response['attachments'][0]['filename']).to eq('rulesets-report.csv')

        post "/api/v1/ticket_attachment_upload_clone_by_article/#{article_p.id}", params: { form_id: '1234-2' }, as: :json
        expect(response).to have_http_status(:ok)
        expect(json_response['attachments']).to be_a(Array)
        expect(json_response['attachments']).to be_blank
      end
    end
  end
end
