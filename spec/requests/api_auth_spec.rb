# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Api Auth', type: :request do

  around do |example|
    orig = ActionController::Base.allow_forgery_protection

    begin
      ActionController::Base.allow_forgery_protection = true
      example.run
    ensure
      ActionController::Base.allow_forgery_protection = orig
    end
  end

  let(:admin)    { create(:admin) }
  let(:agent)    { create(:agent) }
  let(:customer) { create(:customer) }

  let(:two_factor_method_enabled) { true }

  before do
    stub_const('Auth::BRUTE_FORCE_SLEEP', 0)
    Setting.set('two_factor_authentication_method_authenticator_app', two_factor_method_enabled)
  end

  describe 'request handling' do

    it 'does basic auth - admin' do

      Setting.set('api_password_access', false)
      authenticated_as(admin)
      get '/api/v1/sessions', params: {}, as: :json
      expect(response).to have_http_status(:forbidden)
      expect(response.header).not_to be_key('Access-Control-Allow-Origin')
      expect(json_response).to be_a(Hash)
      expect(json_response['error']).to eq('API password access disabled!')

      Setting.set('api_password_access', true)
      get '/api/v1/sessions', params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(response.header['Access-Control-Allow-Origin']).to eq('*')
      expect(response.header['Cache-Control']).to eq('max-age=0, private, must-revalidate')
      expect(json_response).to be_a(Hash)
      expect(json_response).to be_truthy
    end

    it 'does basic auth - agent' do

      Setting.set('api_password_access', false)
      authenticated_as(agent)
      get '/api/v1/tickets', params: {}, as: :json
      expect(response).to have_http_status(:forbidden)
      expect(response.header).not_to be_key('Access-Control-Allow-Origin')
      expect(json_response).to be_a(Hash)
      expect(json_response['error']).to eq('API password access disabled!')

      Setting.set('api_password_access', true)
      get '/api/v1/tickets', params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(response.header['Access-Control-Allow-Origin']).to eq('*')
      expect(response.header['Cache-Control']).to eq('max-age=0, private, must-revalidate')
      expect(json_response).to be_a(Array)
      expect(json_response).to be_truthy
    end

    it 'does basic auth - customer' do

      Setting.set('api_password_access', false)
      authenticated_as(customer)
      get '/api/v1/tickets', params: {}, as: :json
      expect(response).to have_http_status(:forbidden)
      expect(response.header).not_to be_key('Access-Control-Allow-Origin')
      expect(json_response).to be_a(Hash)
      expect(json_response['error']).to eq('API password access disabled!')

      Setting.set('api_password_access', true)
      get '/api/v1/tickets', params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(response.header['Access-Control-Allow-Origin']).to eq('*')
      expect(response.header['Cache-Control']).to eq('max-age=0, private, must-revalidate')
      expect(json_response).to be_a(Array)
      expect(json_response).to be_truthy
    end

    context 'when using BasicAuth with TwoFactor' do
      let!(:two_factor_pref) { create(:user_two_factor_preference, :authenticator_app, user: admin) }

      it 'rejects the log-in' do
        two_factor_pref
        authenticated_as(admin)
        Setting.set('api_password_access', true)
        get '/api/v1/sessions', params: {}, as: :json
        expect(response).to have_http_status(:unauthorized)
      end
    end

    it 'does token auth - admin', last_admin_check: false do

      admin_token = create(
        :token,
        action:      'api',
        persistent:  true,
        user_id:     admin.id,
        preferences: {
          permission: ['admin.session'],
        },
      )

      authenticated_as(admin, token: admin_token)

      Setting.set('api_token_access', false)
      get '/api/v1/sessions', params: {}, as: :json
      expect(response).to have_http_status(:forbidden)
      expect(response.header).not_to be_key('Access-Control-Allow-Origin')
      expect(json_response).to be_a(Hash)
      expect(json_response['error']).to eq('API token access disabled!')

      Setting.set('api_token_access', true)
      get '/api/v1/sessions', params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(response.header['Access-Control-Allow-Origin']).to eq('*')
      expect(response.header['Cache-Control']).to eq('max-age=0, private, must-revalidate')

      expect(json_response).to be_a(Hash)
      expect(json_response).to be_truthy

      admin_token.preferences[:permission] = ['admin.session_not_existing']
      admin_token.save!

      get '/api/v1/sessions', params: {}, as: :json
      expect(response).to have_http_status(:forbidden)
      expect(json_response).to be_a(Hash)
      expect(json_response['error']).to eq('Token authorization failed.')

      admin_token.preferences[:permission] = []
      admin_token.save!

      get '/api/v1/sessions', params: {}, as: :json
      expect(response).to have_http_status(:forbidden)
      expect(json_response).to be_a(Hash)
      expect(json_response['error']).to eq('Token authorization failed.')

      admin.active = false
      admin.save!

      get '/api/v1/sessions', params: {}, as: :json
      expect(response).to have_http_status(:unauthorized)
      expect(json_response).to be_a(Hash)
      expect(json_response['error']).to eq('Login failed. Have you double-checked your credentials and completed the email verification step?')

      admin_token.preferences[:permission] = ['admin.session']
      admin_token.save!

      get '/api/v1/sessions', params: {}, as: :json
      expect(response).to have_http_status(:unauthorized)
      expect(json_response).to be_a(Hash)
      expect(json_response['error']).to eq('Login failed. Have you double-checked your credentials and completed the email verification step?')

      admin.active = true
      admin.save!

      get '/api/v1/sessions', params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a(Hash)
      expect(json_response).to be_truthy

      get '/api/v1/roles', params: {}, as: :json
      expect(response).to have_http_status(:forbidden)
      expect(json_response).to be_a(Hash)
      expect(json_response['error']).to eq('Token authorization failed.')

      admin_token.preferences[:permission] = ['admin.session_not_existing', 'admin.role']
      admin_token.save!

      get '/api/v1/roles', params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a(Array)
      expect(json_response).to be_truthy

      admin_token.preferences[:permission] = ['ticket.agent']
      admin_token.save!

      get '/api/v1/organizations', params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a(Array)
      expect(json_response).to be_truthy

      name = "some org name #{SecureRandom.uuid}"
      post '/api/v1/organizations', params: { name: name }, as: :json
      expect(response).to have_http_status(:created)
      expect(json_response).to be_a(Hash)
      expect(json_response['name']).to eq(name)
      expect(json_response).to be_truthy

      name = "some org name #{SecureRandom.uuid} - 2"
      put "/api/v1/organizations/#{json_response['id']}", params: { name: name }, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a(Hash)
      expect(json_response['name']).to eq(name)
      expect(json_response).to be_truthy

      admin_token.preferences[:permission] = ['admin.organization']
      admin_token.save!

      get '/api/v1/organizations', params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a(Array)
      expect(json_response).to be_truthy

      name = "some org name #{SecureRandom.uuid}"
      post '/api/v1/organizations', params: { name: name }, as: :json
      expect(response).to have_http_status(:created)
      expect(json_response).to be_a(Hash)
      expect(json_response['name']).to eq(name)
      expect(json_response).to be_truthy

      name = "some org name #{SecureRandom.uuid} - 2"
      put "/api/v1/organizations/#{json_response['id']}", params: { name: name }, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a(Hash)
      expect(json_response['name']).to eq(name)
      expect(json_response).to be_truthy

      admin_token.preferences[:permission] = ['admin']
      admin_token.save!

      get '/api/v1/organizations', params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a(Array)
      expect(json_response).to be_truthy

      name = "some org name #{SecureRandom.uuid}"
      post '/api/v1/organizations', params: { name: name }, as: :json
      expect(response).to have_http_status(:created)
      expect(json_response).to be_a(Hash)
      expect(json_response['name']).to eq(name)
      expect(json_response).to be_truthy

      name = "some org name #{SecureRandom.uuid} - 2"
      put "/api/v1/organizations/#{json_response['id']}", params: { name: name }, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a(Hash)
      expect(json_response['name']).to eq(name)
      expect(json_response).to be_truthy

    end

    it 'does token auth - agent' do

      agent_token = create(
        :token,
        action:     'api',
        persistent: true,
        user_id:    agent.id,
      )

      authenticated_as(agent, token: agent_token)

      Setting.set('api_token_access', false)
      get '/api/v1/tickets', params: {}, as: :json
      expect(response).to have_http_status(:forbidden)
      expect(response.header).not_to be_key('Access-Control-Allow-Origin')
      expect(json_response).to be_a(Hash)
      expect(json_response['error']).to eq('API token access disabled!')

      Setting.set('api_token_access', true)
      get '/api/v1/tickets', params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(response.header['Access-Control-Allow-Origin']).to eq('*')
      expect(response.header['Cache-Control']).to eq('max-age=0, private, must-revalidate')
      expect(json_response).to be_a(Array)
      expect(json_response).to be_truthy

      get '/api/v1/organizations', params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a(Array)
      expect(json_response).to be_truthy

      name = "some org name #{SecureRandom.uuid}"
      post '/api/v1/organizations', params: { name: name }, as: :json
      expect(response).to have_http_status(:forbidden)

    end

    it 'does token auth - customer' do

      customer_token = create(
        :token,
        action:     'api',
        persistent: true,
        user_id:    customer.id,
      )

      authenticated_as(customer, token: customer_token)

      Setting.set('api_token_access', false)
      get '/api/v1/tickets', params: {}, as: :json
      expect(response).to have_http_status(:forbidden)
      expect(response.header).not_to be_key('Access-Control-Allow-Origin')
      expect(json_response).to be_a(Hash)
      expect(json_response['error']).to eq('API token access disabled!')

      Setting.set('api_token_access', true)
      get '/api/v1/tickets', params: {}, as: :json
      expect(response.header['Access-Control-Allow-Origin']).to eq('*')
      expect(response.header['Cache-Control']).to eq('max-age=0, private, must-revalidate')
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a(Array)
      expect(json_response).to be_truthy

      get '/api/v1/organizations', params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a(Array)
      expect(json_response).to be_truthy

      name = "some org name #{SecureRandom.uuid}"
      post '/api/v1/organizations', params: { name: name }, as: :json
      expect(response).to have_http_status(:forbidden)
    end

    it 'does token auth - invalid user - admin', last_admin_check: false do

      admin_token = create(
        :token,
        action:     'api',
        persistent: true,
        user_id:    admin.id,
      )

      authenticated_as(admin, token: admin_token)

      admin.active = false
      admin.save!

      Setting.set('api_token_access', false)
      get '/api/v1/sessions', params: {}, as: :json
      expect(response).to have_http_status(:forbidden)
      expect(response.header).not_to be_key('Access-Control-Allow-Origin')
      expect(json_response).to be_a(Hash)
      expect(json_response['error']).to eq('API token access disabled!')

      Setting.set('api_token_access', true)
      get '/api/v1/sessions', params: {}, as: :json
      expect(response).to have_http_status(:unauthorized)
      expect(response.header).not_to be_key('Access-Control-Allow-Origin')
      expect(json_response).to be_a(Hash)
      expect(json_response['error']).to eq('Login failed. Have you double-checked your credentials and completed the email verification step?')
    end

    it 'does token auth - expired' do

      Setting.set('api_token_access', true)

      admin_token = create(
        :token,
        action:     'api',
        persistent: true,
        user_id:    admin.id,
        expires_at: Time.zone.today
      )

      authenticated_as(admin, token: admin_token)

      get '/api/v1/tickets', params: {}, as: :json
      expect(response).to have_http_status(:unauthorized)
      expect(response.header).not_to be_key('Access-Control-Allow-Origin')
      expect(json_response).to be_a(Hash)
      expect(json_response['error']).to eq('Not authorized (token expired)!')

      admin_token.reload
      expect(admin_token.last_used_at).to be_within(1.second).of(Time.zone.now)
    end

    it 'does token auth - not expired' do

      Setting.set('api_token_access', true)

      admin_token = create(
        :token,
        action:     'api',
        persistent: true,
        user_id:    admin.id,
        expires_at: Time.zone.tomorrow
      )

      authenticated_as(admin, token: admin_token)

      get '/api/v1/tickets', params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(response.header['Access-Control-Allow-Origin']).to eq('*')
      expect(response.header['Cache-Control']).to eq('max-age=0, private, must-revalidate')
      expect(json_response).to be_a(Array)
      expect(json_response).to be_truthy

      admin_token.reload
      expect(admin_token.last_used_at).to be_within(1.second).of(Time.zone.now)
    end

    it 'does session auth - admin' do
      admin = create(:admin)

      post '/api/v1/signshow', params: {}, as: :json
      token = response.headers['CSRF-TOKEN']

      post '/api/v1/signin', params: { username: admin.login, password: admin.password, fingerprint: '123456789' }, headers: { 'X-CSRF-Token' => token }
      expect(response.header).not_to be_key('Access-Control-Allow-Origin')
      expect(response).to have_http_status(:created)

      get '/api/v1/sessions', params: {}
      expect(response).to have_http_status(:ok)
      expect(response.header).not_to be_key('Access-Control-Allow-Origin')
      expect(json_response).to be_a(Hash)
      expect(json_response).to be_truthy
    end

    context 'when using session auth with TwoFactor' do
      let(:admin)               { create(:admin) }
      let(:two_factor_method)   { nil }
      let(:two_factor_payload)  { nil }
      let(:code)                { two_factor_pref.configuration[:code] }
      let!(:two_factor_pref)    { create(:user_two_factor_preference, :authenticator_app, user: admin) }

      before do
        post '/api/v1/signshow', params: {}, as: :json
        token = response.headers['CSRF-TOKEN']
        post '/api/v1/signin', params: { username: admin.login, password: admin.password, two_factor_method: two_factor_method, two_factor_payload: two_factor_payload, fingerprint: '123456789' }, headers: { 'X-CSRF-Token' => token }
      end

      context 'without two factor token' do
        it 'rejects the log-in' do
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end

      context 'with wrong two factor token' do
        let(:two_factor_payload) { 'wrong' }
        let(:two_factor_method) { 'authenticator_app' }

        it 'rejects the log-in' do
          expect(response).to have_http_status(:unauthorized)
        end
      end

      context 'with correct two factor token' do
        let(:two_factor_payload) { code }
        let(:two_factor_method) { 'authenticator_app' }

        it 'accepts the log-in' do
          expect(response).to have_http_status(:created)
        end

        context 'with disabled authenticator method' do
          let(:two_factor_method_enabled) { false }

          it 'accepts the log-in' do
            expect(response).to have_http_status(:created)
          end
        end
      end
    end

    it 'does session auth - admin - only with valid CSRF token' do
      create(:admin, login: 'api-admin@example.com', password: 'adminpw')

      post '/api/v1/signin', params: { username: 'api-admin@example.com', password: 'adminpw', fingerprint: '123456789' }
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
