# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'LongPolling', type: :request do

  let(:agent) do
    create(:agent)
  end

  before do
    Sessions.sessions.each do |client_id|
      Sessions.destroy(client_id)
    end
  end

  describe 'request handling' do

    it 'receive without client_id - no user login' do
      post '/api/v1/message_receive', params: { data: {} }, as: :json
      expect(response).to have_http_status(:unprocessable_content)
      expect(json_response).to be_a(Hash)
      expect(json_response['error']).to eq('Invalid client_id received!')
    end

    it 'send without client_id - no user login' do
      post '/api/v1/message_send', params: { data: {} }, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a(Hash)
      expect(json_response['client_id']).to be_a_uuid

      client_id = json_response['client_id']
      post '/api/v1/message_send', params: { client_id: client_id, data: { event: 'anything' } }, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a(Hash)
      expect(json_response['client_id']).to be_a_uuid

      post '/api/v1/message_receive', params: { client_id: client_id, data: {} }, as: :json
      expect(response).to have_http_status(:unprocessable_content)
      expect(json_response).to be_a(Hash)
      expect(json_response['error']).to eq('Invalid client_id received!')
    end

    it 'receive without client_id' do
      authenticated_as(agent, via: :browser)
      post '/api/v1/message_receive', params: { data: {} }, as: :json
      expect(response).to have_http_status(:unprocessable_content)
      expect(json_response).to be_a(Hash)
      expect(json_response['error']).to eq('Invalid client_id received!')
    end

    it 'receive without wrong client_id' do
      authenticated_as(agent, via: :browser)
      post '/api/v1/message_receive', params: { client_id: 'not existing', data: {} }, as: :json
      expect(response).to have_http_status(:unprocessable_content)
      expect(json_response).to be_a(Hash)
      expect(json_response['error']).to eq('Invalid client_id received!')
    end

    it 'send without client_id' do
      authenticated_as(agent, via: :browser)
      post '/api/v1/message_send', params: { data: {} }, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a(Hash)
      expect(json_response['client_id']).to be_a_uuid
    end

    it 'send with client_id' do
      Sessions.create('123456', {}, { type: 'ajax' })
      authenticated_as(agent, via: :browser)
      post '/api/v1/message_send', params: { client_id: '123456', data: {} }, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a(Hash)
      expect(json_response).to eq({})
    end
  end

  describe 'authentication types' do
    let(:token) { create(:token, user: agent, permissions: %w[user_preferences.calendar]) }

    it 'creates a session for a browser session' do
      authenticated_as(agent, via: :browser)
      post '/api/v1/message_send', params: { data: { event: 'login' } }, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response['client_id']).to be_a_uuid
      expect(Sessions.get(json_response['client_id'])).to include(user: { 'id' => agent.id })
    end

    it 'rejects sending via API token' do
      authenticated_as(agent, token: token)
      post '/api/v1/message_send', params: { data: { event: 'login' } }, as: :json
      expect(response).to have_http_status(:forbidden)
      expect(json_response['error']).to eq('Only session based authentication is supported!')
      expect(Sessions.sessions).to be_empty
    end

    it 'rejects receiving via API token' do
      client_id = SecureRandom.uuid
      Sessions.create(client_id, { 'id' => agent.id }, { type: 'ajax' })

      authenticated_as(agent, token: token)
      post '/api/v1/message_receive', params: { client_id: client_id, data: {} }, as: :json
      expect(response).to have_http_status(:forbidden)
      expect(json_response['error']).to eq('Only session based authentication is supported!')
    end

    it 'rejects sending via HTTP basic auth' do
      authenticated_as(agent)
      post '/api/v1/message_send', params: { data: { event: 'login' } }, as: :json
      expect(response).to have_http_status(:forbidden)
      expect(json_response['error']).to eq('Only session based authentication is supported!')
      expect(Sessions.sessions).to be_empty
    end

    it 'rejects receiving via HTTP basic auth' do
      client_id = SecureRandom.uuid
      Sessions.create(client_id, { 'id' => agent.id }, { type: 'ajax' })

      authenticated_as(agent)
      post '/api/v1/message_receive', params: { client_id: client_id, data: {} }, as: :json
      expect(response).to have_http_status(:forbidden)
      expect(json_response['error']).to eq('Only session based authentication is supported!')
    end
  end

  describe 'path traversal protection' do
    it 'rejects client_id containing directory traversal on message_receive' do
      target = Rails.root.join('tmp/poc_path_traversal_test.txt')
      File.write(target, 'still here')

      authenticated_as(agent, via: :browser)
      post '/api/v1/message_receive', params: { client_id: '../poc_path_traversal_test.txt', data: {} }, as: :json

      expect(File.exist?(target)).to be(true)
      expect(response).to have_http_status(:unprocessable_content)
    ensure
      FileUtils.rm_f(target)
    end

    it 'rejects client_id containing directory traversal on message_send' do
      target = Rails.root.join('tmp/poc_path_traversal_send.txt')
      File.write(target, 'still here')

      authenticated_as(agent, via: :browser)
      post '/api/v1/message_send', params: { client_id: '../poc_path_traversal_send.txt', data: { event: 'login' } }, as: :json

      expect(File.exist?(target)).to be(true)
      expect(response).to have_http_status(:ok)
      expect(json_response['client_id']).to be_a_uuid
    ensure
      FileUtils.rm_f(target)
    end

    it 'rejects client_id with null bytes' do
      authenticated_as(agent, via: :browser)
      post '/api/v1/message_receive', params: { client_id: "valid-id\x00/../etc/passwd", data: {} }, as: :json
      expect(response).to have_http_status(:unprocessable_content)
    end

    it 'accepts valid UUID client_id' do
      client_id = SecureRandom.uuid
      Sessions.create(client_id, { 'id' => agent.id }, { type: 'ajax' })

      authenticated_as(agent, via: :browser)
      post '/api/v1/message_send', params: { client_id: client_id, data: {} }, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to eq({})
    end
  end

  describe 'cross-site request handling', allow_forgery_protection: true do
    let(:admin)        { create(:admin) }
    let(:csrf_token)   { response.headers['CSRF-TOKEN'] }
    let(:event_params) { { data: { event: 'maintenance', data: { type: 'message', head: 'head', message: 'message' } } } }

    before do
      allow(Sessions::Event).to receive(:run)

      post '/api/v1/signshow', params: {}, as: :json
      post '/api/v1/signin', params: { username: admin.login, password: admin.password, fingerprint: '123456789' }, headers: { 'X-CSRF-Token' => csrf_token }
    end

    it 'rejects GET requests on message_send', :aggregate_failures do
      get '/api/v1/message_send', params: event_params

      expect(response).to have_http_status(:not_found)
      expect(Sessions::Event).not_to have_received(:run)
    end

    it 'rejects GET requests on message_receive' do
      get '/api/v1/message_receive', params: { client_id: '123456', data: {} }

      expect(response).to have_http_status(:not_found)
    end

    it 'rejects POST requests on message_send without CSRF token', :aggregate_failures do
      post '/api/v1/message_send', params: event_params, as: :json

      expect(response).to have_http_status(:unauthorized)
      expect(json_response['invalid_csrf_token']).to be(true)
      expect(Sessions::Event).not_to have_received(:run)
    end

    it 'accepts POST requests on message_send with CSRF token', :aggregate_failures do
      post '/api/v1/message_send', params: event_params, headers: { 'X-CSRF-Token' => csrf_token }, as: :json

      expect(response).to have_http_status(:ok)
      expect(Sessions::Event).to have_received(:run).with(hash_including(event: 'maintenance'))
    end
  end
end
