# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

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
      expect(response).to have_http_status(:unprocessable_entity)
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
      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_response).to be_a(Hash)
      expect(json_response['error']).to eq('Invalid client_id received!')
    end

    it 'receive without client_id' do
      authenticated_as(agent)
      get '/api/v1/message_receive', params: { data: {} }, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_response).to be_a(Hash)
      expect(json_response['error']).to eq('Invalid client_id received!')
    end

    it 'receive without wrong client_id' do
      authenticated_as(agent)
      get '/api/v1/message_receive', params: { client_id: 'not existing', data: {} }, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
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
end
