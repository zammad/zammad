require 'rails_helper'

RSpec.describe 'Ticket Article Attachments', type: :request do

  let(:agent_user) do
    create(:agent_user, groups: Group.all)
  end

  describe 'request handling' do

    it 'does test attachment urls' do
      ticket1  = create(:ticket)
      article1 = create(:ticket_article, ticket_id: ticket1.id)

      store1 = Store.add(
        object: 'Ticket::Article',
        o_id: article1.id,
        data: 'some content',
        filename: 'some_file.txt',
        preferences: {
          'Content-Type' => 'text/plain',
        },
        created_by_id: 1,
      )
      article2 = create(:ticket_article, ticket_id: ticket1.id)

      authenticated_as(agent_user)
      get "/api/v1/ticket_attachment/#{ticket1.id}/#{article1.id}/#{store1.id}", params: {}
      expect(response).to have_http_status(200)
      expect('some content').to eq(@response.body)

      authenticated_as(agent_user)
      get "/api/v1/ticket_attachment/#{ticket1.id}/#{article2.id}/#{store1.id}", params: {}
      expect(response).to have_http_status(401)
      expect(@response.body).to match(/401: Unauthorized/)

      ticket2 = create(:ticket)
      ticket1.merge_to(
        ticket_id: ticket2.id,
        user_id:   1,
      )

      authenticated_as(agent_user)
      get "/api/v1/ticket_attachment/#{ticket2.id}/#{article1.id}/#{store1.id}", params: {}
      expect(response).to have_http_status(200)
      expect('some content').to eq(@response.body)

      authenticated_as(agent_user)
      get "/api/v1/ticket_attachment/#{ticket2.id}/#{article2.id}/#{store1.id}", params: {}
      expect(response).to have_http_status(401)
      expect(@response.body).to match(/401: Unauthorized/)

      # allow access via merged ticket id also
      authenticated_as(agent_user)
      get "/api/v1/ticket_attachment/#{ticket1.id}/#{article1.id}/#{store1.id}", params: {}
      expect(response).to have_http_status(200)
      expect('some content').to eq(@response.body)

      authenticated_as(agent_user)
      get "/api/v1/ticket_attachment/#{ticket1.id}/#{article2.id}/#{store1.id}", params: {}
      expect(response).to have_http_status(401)
      expect(@response.body).to match(/401: Unauthorized/)

    end

    it 'does test attachments for split' do
      email_file_path  = Rails.root.join('test', 'data', 'mail', 'mail024.box')
      email_raw_string = File.read(email_file_path)
      ticket_p, article_p, user_p = Channel::EmailParser.new.process({}, email_raw_string)

      authenticated_as(agent_user)
      get '/api/v1/ticket_split', params: { form_id: '1234-2', ticket_id: ticket_p.id, article_id: article_p.id }, as: :json
      expect(response).to have_http_status(200)
      expect(json_response['assets']).to be_truthy
      expect(json_response['attachments']).to be_a_kind_of(Array)
      expect(json_response['attachments'].count).to eq(1)
      expect(json_response['attachments'][0]['filename']).to eq('rulesets-report.csv')

    end

    it 'does test attachments for forward' do
      email_file_path  = Rails.root.join('test', 'data', 'mail', 'mail008.box')
      email_raw_string = File.read(email_file_path)
      ticket_p, article_p, user_p = Channel::EmailParser.new.process({}, email_raw_string)

      authenticated_as(agent_user)
      post "/api/v1/ticket_attachment_upload_clone_by_article/#{article_p.id}", params: {}, as: :json
      expect(response).to have_http_status(422)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['error']).to eq('Need form_id to attach attachments to new form.')

      post "/api/v1/ticket_attachment_upload_clone_by_article/#{article_p.id}", params: { form_id: '1234-1' }, as: :json
      expect(response).to have_http_status(200)
      expect(json_response['attachments']).to be_a_kind_of(Array)
      expect(json_response['attachments']).to be_blank

      email_file_path  = Rails.root.join('test', 'data', 'mail', 'mail024.box')
      email_raw_string = File.read(email_file_path)
      ticket_p, article_p, user_p = Channel::EmailParser.new.process({}, email_raw_string)

      post "/api/v1/ticket_attachment_upload_clone_by_article/#{article_p.id}", params: { form_id: '1234-2' }, as: :json
      expect(response).to have_http_status(200)
      expect(json_response['attachments']).to be_a_kind_of(Array)
      expect(json_response['attachments'].count).to eq(1)
      expect(json_response['attachments'][0]['filename']).to eq('rulesets-report.csv')

      post "/api/v1/ticket_attachment_upload_clone_by_article/#{article_p.id}", params: { form_id: '1234-2' }, as: :json
      expect(response).to have_http_status(200)
      expect(json_response['attachments']).to be_a_kind_of(Array)
      expect(json_response['attachments']).to be_blank
    end
  end
end
