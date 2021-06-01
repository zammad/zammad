# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'LongPolling', type: :request do

  let(:agent) do
    create(:agent)
  end

  before do
    Sessions.sessions.each do |client_id|
      Sessions.destroy(client_id)
    end
    Sessions.spool_delete
  end

  describe 'request handling' do

    it 'receive without client_id - no user login' do
      get '/api/v1/message_receive', params: { data: {} }, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['error']).to eq('Invalid client_id receive!')
    end

    it 'send without client_id - no user login' do
      get '/api/v1/message_send', params: { data: {} }, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['client_id'].to_i).to be_between(1, 9_999_999_999)

      client_id = json_response['client_id']
      get '/api/v1/message_send', params: { client_id: client_id, data: { event: 'spool' } }, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['client_id'].to_i).to be_between(1, 9_999_999_999)

      get '/api/v1/message_receive', params: { client_id: client_id, data: {} }, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['error']).to eq('Invalid client_id receive!')
    end

    it 'receive without client_id' do
      authenticated_as(agent)
      get '/api/v1/message_receive', params: { data: {} }, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['error']).to eq('Invalid client_id receive!')
    end

    it 'receive without wrong client_id' do
      authenticated_as(agent)
      get '/api/v1/message_receive', params: { client_id: 'not existing', data: {} }, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['error']).to eq('Invalid client_id receive!')
    end

    it 'send without client_id' do
      authenticated_as(agent)
      get '/api/v1/message_send', params: { data: {} }, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['client_id'].to_i).to be_between(1, 9_999_999_999)
    end

    it 'send with client_id' do
      Sessions.create('123456', {}, { type: 'ajax' })
      authenticated_as(agent)
      get '/api/v1/message_send', params: { client_id: '123456', data: {} }, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response).to eq({})
    end

    it 'send event spool and receive data' do

      # here we use a token for the authentication because the basic auth way with username and password
      # will update the user by every request and return a different result for the test
      authenticated_as(agent, token: create(:token, action: 'api', user_id: agent.id) )
      get '/api/v1/message_send', params: { data: { event: 'login' } }, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response['client_id'].to_i).to be_between(1, 9_999_999_999)
      client_id = json_response['client_id']

      get '/api/v1/message_receive', params: { client_id: client_id, data: {} }, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Array)
      expect(json_response).to eq([{ 'data' => { 'success' => true }, 'event' => 'ws:login' }])

      get '/api/v1/message_send', params: { client_id: client_id, data: { event: 'spool' } }, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response).to eq({})

      get '/api/v1/message_receive', params: { client_id: client_id, data: {} }, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Array)
      expect(json_response[0]['event']).to eq('spool:sent')
      expect(json_response[0]['event']).to eq('spool:sent')
      expect(json_response.count).to eq(1)

      spool_list = Sessions.spool_list(Time.now.utc.to_i, agent.id)
      expect(spool_list).to eq([])

      get '/api/v1/message_send', params: { client_id: client_id, data: { event: 'broadcast', spool: true, recipient: { user_id: [agent.id] }, data: { taskbar_id: 9_391_633 } } }, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response).to eq({})

      get '/api/v1/message_receive', params: { client_id: client_id, data: {} }, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response).to eq({ 'event' => 'pong' })

      travel 2.seconds

      spool_list = Sessions.spool_list(Time.now.utc.to_i, agent.id)
      expect(spool_list).to eq([])

      spool_list = Sessions.spool_list(nil, agent.id)
      expect(spool_list).to eq([{ message: { 'taskbar_id' => 9_391_633 }, type: 'direct' }])
    end

  end
end
