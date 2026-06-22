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
      get '/api/v1/message_receive', params: { data: {} }, as: :json
      expect(response).to have_http_status(:unprocessable_content)
      expect(json_response).to be_a(Hash)
      expect(json_response['error']).to eq('Invalid client_id received!')
    end

    it 'send without client_id - no user login' do
      get '/api/v1/message_send', params: { data: {} }, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a(Hash)
      expect(json_response['client_id']).to be_a_uuid

      client_id = json_response['client_id']
      get '/api/v1/message_send', params: { client_id: client_id, data: { event: 'anything' } }, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a(Hash)
      expect(json_response['client_id']).to be_a_uuid

      get '/api/v1/message_receive', params: { client_id: client_id, data: {} }, as: :json
      expect(response).to have_http_status(:unprocessable_content)
      expect(json_response).to be_a(Hash)
      expect(json_response['error']).to eq('Invalid client_id received!')
    end

    it 'receive without client_id' do
      authenticated_as(agent)
      get '/api/v1/message_receive', params: { data: {} }, as: :json
      expect(response).to have_http_status(:unprocessable_content)
      expect(json_response).to be_a(Hash)
      expect(json_response['error']).to eq('Invalid client_id received!')
    end

    it 'receive without wrong client_id' do
      authenticated_as(agent)
      get '/api/v1/message_receive', params: { client_id: 'not existing', data: {} }, as: :json
      expect(response).to have_http_status(:unprocessable_content)
      expect(json_response).to be_a(Hash)
      expect(json_response['error']).to eq('Invalid client_id received!')
    end

    it 'send without client_id' do
      authenticated_as(agent)
      get '/api/v1/message_send', params: { data: {} }, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a(Hash)
      expect(json_response['client_id']).to be_a_uuid
    end

    it 'send with client_id' do
      Sessions.create('123456', {}, { type: 'ajax' })
      authenticated_as(agent)
      get '/api/v1/message_send', params: { client_id: '123456', data: {} }, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a(Hash)
      expect(json_response).to eq({})
    end
  end

  describe 'path traversal protection' do
    it 'rejects client_id containing directory traversal on message_receive' do
      target = Rails.root.join('tmp/poc_path_traversal_test.txt')
      File.write(target, 'still here')

      authenticated_as(agent)
      get '/api/v1/message_receive', params: { client_id: '../poc_path_traversal_test.txt', data: {} }, as: :json

      expect(File.exist?(target)).to be(true)
      expect(response).to have_http_status(:unprocessable_content)
    ensure
      FileUtils.rm_f(target)
    end

    it 'rejects client_id containing directory traversal on message_send' do
      target = Rails.root.join('tmp/poc_path_traversal_send.txt')
      File.write(target, 'still here')

      authenticated_as(agent)
      get '/api/v1/message_send', params: { client_id: '../poc_path_traversal_send.txt', data: { event: 'login' } }, as: :json

      expect(File.exist?(target)).to be(true)
      expect(response).to have_http_status(:ok)
      expect(json_response['client_id']).to be_a_uuid
    ensure
      FileUtils.rm_f(target)
    end

    it 'rejects client_id with null bytes' do
      authenticated_as(agent)
      get '/api/v1/message_receive', params: { client_id: "valid-id\x00/../etc/passwd", data: {} }, as: :json
      expect(response).to have_http_status(:unprocessable_content)
    end

    it 'accepts valid UUID client_id' do
      client_id = SecureRandom.uuid
      Sessions.create(client_id, { 'id' => agent.id }, { type: 'ajax' })

      authenticated_as(agent)
      get '/api/v1/message_send', params: { client_id: client_id, data: {} }, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to eq({})
    end
  end
end
