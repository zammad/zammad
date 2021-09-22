# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

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
      let(:ticket2) { create(:ticket, group: group) }
      let(:article2) { create(:ticket_article, ticket: ticket2) }

      let(:store_file_content_type) { 'text/plain' }
      let!(:store_file) do
        Store.add(
          object:        'Ticket::Article',
          o_id:          article1.id,
          data:          'some content',
          filename:      'some_file.txt',
          preferences:   {
            'Content-Type' => store_file_content_type,
          },
          created_by_id: 1,
        )
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
        expect(json_response['attachments']).to be_a_kind_of(Array)
        expect(json_response['attachments'].count).to eq(1)
        expect(json_response['attachments'][0]['filename']).to eq('rulesets-report.csv')

      end

      it 'does test attachments for forward' do
        email_file_path  = Rails.root.join('test/data/mail/mail008.box')
        email_raw_string = File.read(email_file_path)
        _ticket_p, article_p, _user_p = Channel::EmailParser.new.process({}, email_raw_string)

        post "/api/v1/ticket_attachment_upload_clone_by_article/#{article_p.id}", params: {}, as: :json
        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response).to be_a_kind_of(Hash)
        expect(json_response['error']).to eq('Need form_id to attach attachments to new form.')

        post "/api/v1/ticket_attachment_upload_clone_by_article/#{article_p.id}", params: { form_id: '1234-1' }, as: :json
        expect(response).to have_http_status(:ok)
        expect(json_response['attachments']).to be_a_kind_of(Array)
        expect(json_response['attachments']).to be_blank

        email_file_path  = Rails.root.join('test/data/mail/mail024.box')
        email_raw_string = File.read(email_file_path)
        _ticket_p, article_p, _user_p = Channel::EmailParser.new.process({}, email_raw_string)

        post "/api/v1/ticket_attachment_upload_clone_by_article/#{article_p.id}", params: { form_id: '1234-2' }, as: :json
        expect(response).to have_http_status(:ok)
        expect(json_response['attachments']).to be_a_kind_of(Array)
        expect(json_response['attachments'].count).to eq(1)
        expect(json_response['attachments'][0]['filename']).to eq('rulesets-report.csv')

        post "/api/v1/ticket_attachment_upload_clone_by_article/#{article_p.id}", params: { form_id: '1234-2' }, as: :json
        expect(response).to have_http_status(:ok)
        expect(json_response['attachments']).to be_a_kind_of(Array)
        expect(json_response['attachments']).to be_blank
      end
    end
  end
end
