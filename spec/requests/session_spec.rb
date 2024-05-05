# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Sessions endpoints', type: :request do

  describe 'GET /' do

    let(:headers)     { {} }
    let(:session_key) { Zammad::Application::Initializer::SessionStore::SESSION_KEY }

    before do
      Setting.set('http_type', http_type)

      get '/', headers: headers
    end

    context "when Setting 'http_type' is set to 'https'" do

      let(:http_type) { 'https' }

      context "when it's not an HTTPS request" do

        it 'sets no Cookie' do
          expect(response.header['Set-Cookie']).to be_nil
        end
      end

      context "when it's an HTTPS request" do

        let(:headers) do
          {
            'X-Forwarded-Proto' => 'https'
          }
        end

        it "sets Cookie with 'secure' flag" do
          expect(response.header['Set-Cookie']).to include(session_key).and include('; secure;')
        end
      end
    end

    context "when Setting 'http_type' is set to 'http'" do

      let(:http_type) { 'http' }

      context "when it's not an HTTPS request" do

        it 'sets Cookie' do
          expect(response.header['Set-Cookie']).to include(session_key).and not_include('; secure;')
        end
      end

      context "when it's an HTTPS request" do

        let(:headers) do
          {
            'X-Forwarded-Proto' => 'https'
          }
        end

        it "sets Cookie without 'secure' flag" do
          expect(response.header['Set-Cookie']).to include(session_key).and not_include('; secure;')
        end
      end
    end
  end

  describe 'GET /signshow' do

    context 'user logged in' do

      subject(:user) { create(:agent, password: password) }

      let(:password) { SecureRandom.urlsafe_base64(20) }
      let(:fingerprint) { SecureRandom.urlsafe_base64(40) }

      before do
        setting if defined?(setting)

        params = {
          fingerprint: fingerprint,
          username:    user.login,
          password:    password
        }
        post '/api/v1/signin', params: params, as: :json
      end

      it 'leaks no sensitive data' do
        params = { fingerprint: fingerprint }
        get '/api/v1/signshow', params: params, as: :json

        expect(json_response['session']).not_to include('password')
      end

      context 'when after auth modules are triggered' do
        subject(:user) { create(:customer, roles: [role], password: password) }

        let(:role)     { create(:role, name: '2FA') }

        context 'with no enforcing roles' do
          it 'returns nil' do
            expect(json_response['after_auth']).to be_nil
          end
        end

        context 'with enforcing roles' do
          let(:setting) do
            Setting.set('two_factor_authentication_enforce_role_ids', [role.id])
            Setting.set('two_factor_authentication_method_authenticator_app', true)
          end

          it 'returns the after auth information' do
            expect(json_response['after_auth']).to eq({ 'data' => {}, 'type' => 'TwoFactorConfiguration' })
          end
        end
      end
    end

    context 'user not logged in' do
      subject(:user) { nil }

      it 'contains only user related object manager attributes' do
        get '/api/v1/signshow', params: {}, as: :json

        expect(json_response['models'].keys).to match_array(%w[User])
      end

      it 'does not contain fields with permission admin.*' do
        get '/api/v1/signshow', params: {}, as: :json

        expect(json_response['models']['User']).not_to include(hash_including('name' => 'role_ids'))
      end
    end
  end

  describe 'GET /auth/sso (single sign-on)' do

    before do
      Setting.set('auth_sso', true)
    end

    context 'when SSO is disabled' do

      before do
        Setting.set('auth_sso', false)
      end

      let(:headers) { { 'X-Forwarded-User' => login } }
      let(:login)   { User.last.login }

      it 'returns a new user-session response' do
        get '/auth/sso', as: :json, headers: headers

        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'with invalid user login' do
      let(:login) { User.pluck(:login).max.next }

      context 'in "REMOTE_USER" request env var' do
        let(:env) { { 'REMOTE_USER' => login } }

        it 'returns unauthorized response' do
          get '/auth/sso', as: :json, env: env

          expect(response).to have_http_status(:unauthorized)
        end
      end

      context 'in "HTTP_REMOTE_USER" request env var' do
        let(:env) { { 'HTTP_REMOTE_USER' => login } }

        it 'returns unauthorized response' do
          get '/auth/sso', as: :json, env: env

          expect(response).to have_http_status(:unauthorized)
        end
      end

      context 'in "X-Forwarded-User" request header' do
        let(:headers) { { 'X-Forwarded-User' => login } }

        it 'returns unauthorized response' do
          get '/auth/sso', as: :json, headers: headers

          expect(response).to have_http_status(:unauthorized)
        end
      end
    end

    context 'with valid user login' do
      let(:user) { create(:agent) }
      let(:login) { user.login }

      context 'in Maintenance Mode' do
        before { Setting.set('maintenance_mode', true) }

        context 'in "REMOTE_USER" request env var' do
          let(:env) { { 'REMOTE_USER' => login } }

          it 'returns 403 Forbidden' do
            get '/auth/sso', as: :json, env: env

            expect(response).to have_http_status(:forbidden)
            expect(json_response).to include('error' => 'Maintenance mode enabled!')
          end
        end

        context 'in "HTTP_REMOTE_USER" request env var' do
          let(:env) { { 'HTTP_REMOTE_USER' => login } }

          it 'returns 403 Forbidden' do
            get '/auth/sso', as: :json, env: env

            expect(response).to have_http_status(:forbidden)
            expect(json_response).to include('error' => 'Maintenance mode enabled!')
          end
        end

        context 'in "X-Forwarded-User" request header' do
          let(:headers) { { 'X-Forwarded-User' => login } }

          it 'returns 403 Forbidden' do
            get '/auth/sso', as: :json, headers: headers

            expect(response).to have_http_status(:forbidden)
            expect(json_response).to include('error' => 'Maintenance mode enabled!')
          end
        end
      end

      context 'in "REMOTE_USER" request env var' do
        let(:env) { { 'REMOTE_USER' => login } }

        it 'returns a new user-session response' do
          get '/auth/sso', as: :json, env: env

          expect(response).to redirect_to('/#')
        end

        it 'sets the :user_id session parameter' do
          expect { get '/auth/sso', as: :json, env: env }
            .to change { request&.session&.fetch(:user_id) }.to(user.id)
        end
      end

      context 'in "HTTP_REMOTE_USER" request env var' do
        let(:env) { { 'HTTP_REMOTE_USER' => login } }

        it 'returns a new user-session response' do
          get '/auth/sso', as: :json, env: env

          expect(response).to redirect_to('/#')
        end

        it 'sets the :user_id session parameter' do
          expect { get '/auth/sso', as: :json, env: env }
            .to change { request&.session&.fetch(:user_id) }.to(user.id)
        end
      end

      context 'in "X-Forwarded-User" request header' do
        let(:headers) { { 'X-Forwarded-User' => login } }

        it 'returns a new user-session response' do
          get '/auth/sso', as: :json, headers: headers

          expect(response).to redirect_to('/#')
        end

        it 'sets the :user_id session parameter on the client' do
          expect { get '/auth/sso', as: :json, headers: headers }
            .to change { request&.session&.fetch(:user_id) }.to(user.id)
        end
      end
    end
  end

  describe 'POST /auth/two_factor_itwo_factor_method_enablednitiate_authentication/:method' do
    let(:user)                       { create(:user, password: 'dummy') }
    let(:params)                     { {} }
    let(:method)                     { 'security_keys' }
    let(:user_two_factor_preference) { nil }
    let(:two_factor_method_enabled)  { true }

    before do
      Setting.set('two_factor_authentication_method_security_keys', two_factor_method_enabled)

      if defined?(user_two_factor_preference)
        user_two_factor_preference
        user.reload
      end

      post "/api/v1/auth/two_factor_initiate_authentication/#{method}", params: params, as: :json
    end

    context 'with missing params' do
      it 'returns an error' do
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'with valid params' do
      let(:user_two_factor_preference) { create(:user_two_factor_preference, :security_keys, user: user) }
      let(:params)                     { { username: user.login, password: password, method: method } }

      context 'with invalid user/password' do
        let(:password) { 'invalid' }

        it 'returns an error' do
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end

      context 'with valid user/password' do
        let(:password) { 'dummy' }

        it 'returns options for initiation phase', :aggregate_failures do
          expect(response).to have_http_status(:ok)
          expect(json_response).to include('challenge')
        end

        context 'with disabled authenticator method' do
          let(:two_factor_method_enabled) { false }

          it 'returns an error' do
            expect(response).to have_http_status(:unprocessable_entity)
          end
        end
      end
    end
  end
end
