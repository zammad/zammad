# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Ticket Article Attachments', type: :request do

  let(:group) { create(:group) }

  let(:agent) do
    create(:agent, groups: [Group.lookup(name: 'Users'), group])
  end

  describe 'request handling' do

    it 'does test attachment urls' do
      ticket1  = create(:ticket, group: group)
      article1 = create(:ticket_article, ticket_id: ticket1.id)

      store1 = Store.add(
        object:        'Ticket::Article',
        o_id:          article1.id,
        data:          'some content',
        filename:      'some_file.txt',
        preferences:   {
          'Content-Type' => 'text/plain',
        },
        created_by_id: 1,
      )
      article2 = create(:ticket_article, ticket_id: ticket1.id)

      authenticated_as(agent)
      get "/api/v1/ticket_attachment/#{ticket1.id}/#{article1.id}/#{store1.id}", params: {}
      expect(response).to have_http_status(:ok)
      expect('some content').to eq(@response.body)

      authenticated_as(agent)
      get "/api/v1/ticket_attachment/#{ticket1.id}/#{article2.id}/#{store1.id}", params: {}
      expect(response).to have_http_status(:forbidden)
      expect(@response.body).to match(%r{403: Forbidden})

      ticket2 = create(:ticket, group: group)
      ticket1.merge_to(
        ticket_id: ticket2.id,
        user_id:   1,
      )

      authenticated_as(agent)
      get "/api/v1/ticket_attachment/#{ticket2.id}/#{article1.id}/#{store1.id}", params: {}
      expect(response).to have_http_status(:ok)
      expect('some content').to eq(@response.body)

      authenticated_as(agent)
      get "/api/v1/ticket_attachment/#{ticket2.id}/#{article2.id}/#{store1.id}", params: {}
      expect(response).to have_http_status(:forbidden)
      expect(@response.body).to match(%r{403: Forbidden})

      # allow access via merged ticket id also
      authenticated_as(agent)
      get "/api/v1/ticket_attachment/#{ticket1.id}/#{article1.id}/#{store1.id}", params: {}
      expect(response).to have_http_status(:ok)
      expect('some content').to eq(@response.body)

      authenticated_as(agent)
      get "/api/v1/ticket_attachment/#{ticket1.id}/#{article2.id}/#{store1.id}", params: {}
      expect(response).to have_http_status(:forbidden)
      expect(@response.body).to match(%r{403: Forbidden})

    end

    it 'does test attachments for split' do
      email_file_path  = Rails.root.join('test/data/mail/mail024.box')
      email_raw_string = File.read(email_file_path)
      ticket_p, article_p, _user_p = Channel::EmailParser.new.process({}, email_raw_string)

      authenticated_as(agent)
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

      authenticated_as(agent)
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
