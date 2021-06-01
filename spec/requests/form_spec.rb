# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Form', type: :request, searchindex: true do

  before do
    configure_elasticsearch
    rebuild_searchindex
  end

  describe 'request handling' do

    it 'does get config call' do
      post '/api/v1/form_config', params: {}, as: :json
      expect(response).to have_http_status(:forbidden)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['error']).to eq('Not authorized')
    end

    it 'does get config call' do
      Setting.set('form_ticket_create', true)
      post '/api/v1/form_config', params: {}, as: :json
      expect(response).to have_http_status(:forbidden)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['error']).to eq('Not authorized')

    end

    it 'does get config call & do submit' do
      Setting.set('form_ticket_create', true)
      fingerprint = SecureRandom.hex(40)
      post '/api/v1/form_config', params: { fingerprint: fingerprint }, as: :json

      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['enabled']).to eq(true)
      expect(json_response['endpoint']).to eq('http://zammad.example.com/api/v1/form_submit')
      expect(json_response['token']).to be_truthy
      token = json_response['token']

      post '/api/v1/form_submit', params: { fingerprint: fingerprint, token: 'invalid' }, as: :json
      expect(response).to have_http_status(:unauthorized)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['error']).to eq('Authorization failed')

      post '/api/v1/form_submit', params: { fingerprint: fingerprint, token: token }, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Hash)

      expect(json_response['errors']).to be_truthy
      expect(json_response['errors']['name']).to eq('required')
      expect(json_response['errors']['email']).to eq('required')
      expect(json_response['errors']['title']).to eq('required')
      expect(json_response['errors']['body']).to eq('required')

      post '/api/v1/form_submit', params: { fingerprint: fingerprint, token: token, email: 'some' }, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Hash)

      expect(json_response['errors']).to be_truthy
      expect(json_response['errors']['name']).to eq('required')
      expect(json_response['errors']['email']).to eq('invalid')
      expect(json_response['errors']['title']).to eq('required')
      expect(json_response['errors']['body']).to eq('required')

      post '/api/v1/form_submit', params: { fingerprint: fingerprint, token: token, name: 'Bob Smith', email: 'discard@znuny.com', title: 'test', body: 'hello' }, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Hash)

      expect(json_response['errors']).to be_falsey
      expect(json_response['ticket']).to be_truthy
      expect(json_response['ticket']['id']).to be_truthy
      expect(json_response['ticket']['number']).to be_truthy

      travel 5.hours

      post '/api/v1/form_submit', params: { fingerprint: fingerprint, token: token, name: 'Bob Smith', email: 'discard@znuny.com', title: 'test', body: 'hello' }, as: :json

      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Hash)

      expect(json_response['errors']).to be_falsey
      expect(json_response['ticket']).to be_truthy
      expect(json_response['ticket']['id']).to be_truthy
      expect(json_response['ticket']['number']).to be_truthy

      travel 20.hours

      post '/api/v1/form_submit', params: { fingerprint: fingerprint, token: token, name: 'Bob Smith', email: 'discard@znuny.com', title: 'test', body: 'hello' }, as: :json
      expect(response).to have_http_status(:unauthorized)

    end

    it 'does get config call & do submit' do
      Setting.set('form_ticket_create', true)
      fingerprint = SecureRandom.hex(40)
      post '/api/v1/form_config', params: { fingerprint: fingerprint }, as: :json

      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['enabled']).to eq(true)
      expect(json_response['endpoint']).to eq('http://zammad.example.com/api/v1/form_submit')
      expect(json_response['token']).to be_truthy
      token = json_response['token']

      post '/api/v1/form_submit', params: { fingerprint: fingerprint, token: 'invalid' }, as: :json
      expect(response).to have_http_status(:unauthorized)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['error']).to eq('Authorization failed')

      post '/api/v1/form_submit', params: { fingerprint: fingerprint, token: token }, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Hash)

      expect(json_response['errors']).to be_truthy
      expect(json_response['errors']['name']).to eq('required')
      expect(json_response['errors']['email']).to eq('required')
      expect(json_response['errors']['title']).to eq('required')
      expect(json_response['errors']['body']).to eq('required')

      post '/api/v1/form_submit', params: { fingerprint: fingerprint, token: token, email: 'some' }, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Hash)

      expect(json_response['errors']).to be_truthy
      expect(json_response['errors']['name']).to eq('required')
      expect(json_response['errors']['email']).to eq('invalid')
      expect(json_response['errors']['title']).to eq('required')
      expect(json_response['errors']['body']).to eq('required')

      post '/api/v1/form_submit', params: { fingerprint: fingerprint, token: token, name: 'Bob Smith', email: 'somebody@somedomainthatisinvalid.com', title: 'test', body: 'hello' }, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Hash)

      expect(json_response['errors']).to be_truthy
      expect(json_response['errors']['email']).to eq('invalid')

    end

    it 'does limits' do
      skip('No ES configured') if !SearchIndexBackend.enabled?

      Setting.set('form_ticket_create', true)
      fingerprint = SecureRandom.hex(40)
      post '/api/v1/form_config', params: { fingerprint: fingerprint }, as: :json

      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['enabled']).to eq(true)
      expect(json_response['endpoint']).to eq('http://zammad.example.com/api/v1/form_submit')
      expect(json_response['token']).to be_truthy
      token = json_response['token']

      (1..20).each do |count|
        post '/api/v1/form_submit', params: { fingerprint: fingerprint, token: token, name: 'Bob Smith', email: 'discard@znuny.com', title: "test#{count}", body: 'hello' }, as: :json
        expect(response).to have_http_status(:ok)
        expect(json_response).to be_a_kind_of(Hash)

        expect(json_response['errors']).to be_falsey
        expect(json_response['ticket']).to be_truthy
        expect(json_response['ticket']['id']).to be_truthy
        Scheduler.worker(true)
      end

      sleep 10 # wait until elasticsearch is index

      post '/api/v1/form_submit', params: { fingerprint: fingerprint, token: token, name: 'Bob Smith', email: 'discard@znuny.com', title: 'test-last', body: 'hello' }, as: :json
      expect(response).to have_http_status(:forbidden)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['error']).to be_truthy

      @headers = { 'ACCEPT' => 'application/json', 'CONTENT_TYPE' => 'application/json', 'REMOTE_ADDR' => '1.2.3.5' }

      (1..20).each do |count|
        post '/api/v1/form_submit', params: { fingerprint: fingerprint, token: token, name: 'Bob Smith', email: 'discard@znuny.com', title: "test-2-#{count}", body: 'hello' }, as: :json
        expect(response).to have_http_status(:ok)
        expect(json_response).to be_a_kind_of(Hash)

        expect(json_response['errors']).to be_falsey
        expect(json_response['ticket']).to be_truthy
        expect(json_response['ticket']['id']).to be_truthy
        Scheduler.worker(true)
      end

      sleep 10 # wait until elasticsearch is index

      post '/api/v1/form_submit', params: { fingerprint: fingerprint, token: token, name: 'Bob Smith', email: 'discard@znuny.com', title: 'test-2-last', body: 'hello' }, as: :json
      expect(response).to have_http_status(:forbidden)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['error']).to be_truthy

      @headers = { 'ACCEPT' => 'application/json', 'CONTENT_TYPE' => 'application/json', 'REMOTE_ADDR' => '::1' }

      (1..20).each do |count|
        post '/api/v1/form_submit', params: { fingerprint: fingerprint, token: token, name: 'Bob Smith', email: 'discard@znuny.com', title: "test-2-#{count}", body: 'hello' }, as: :json
        expect(response).to have_http_status(:ok)
        expect(json_response).to be_a_kind_of(Hash)

        expect(json_response['errors']).to be_falsey
        expect(json_response['ticket']).to be_truthy
        expect(json_response['ticket']['id']).to be_truthy
        Scheduler.worker(true)
      end

      sleep 10 # wait until elasticsearch is index

      post '/api/v1/form_submit', params: { fingerprint: fingerprint, token: token, name: 'Bob Smith', email: 'discard@znuny.com', title: 'test-2-last', body: 'hello' }, as: :json
      expect(response).to have_http_status(:forbidden)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['error']).to be_truthy
    end

    it 'does customer_ticket_create false disables form' do
      Setting.set('form_ticket_create', false)
      Setting.set('customer_ticket_create', true)

      fingerprint = SecureRandom.hex(40)

      post '/api/v1/form_config', params: { fingerprint: fingerprint }, as: :json

      token = json_response['token']
      params = {
        fingerprint: fingerprint,
        token:       token,
        name:        'Bob Smith',
        email:       'discard@znuny.com',
        title:       'test',
        body:        'hello'
      }

      post '/api/v1/form_submit', params: params, as: :json

      expect(response).to have_http_status(:forbidden)
    end
  end
end
