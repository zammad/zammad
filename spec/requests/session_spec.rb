require 'rails_helper'

RSpec.describe 'Sessions endpoints', type: :request do

  describe 'GET /signshow' do

    context 'user logged in' do

      subject(:user) { create(:agent_user, password: password) }

      let(:password) { SecureRandom.urlsafe_base64(20) }
      let(:fingerprint) { SecureRandom.urlsafe_base64(40) }

      before do
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
    end
  end

  describe 'GET /auth/sso (single sign-on)' do
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
      let(:user) { User.last }
      let(:login) { user.login }

      context 'in Maintenance Mode' do
        before { Setting.set('maintenance_mode', true) }

        context 'in "REMOTE_USER" request env var' do
          let(:env) { { 'REMOTE_USER' => login } }

          it 'returns 401 unauthorized' do
            get '/auth/sso', as: :json, env: env

            expect(response).to have_http_status(:unauthorized)
            expect(json_response).to include('error' => 'Maintenance mode enabled!')
          end
        end

        context 'in "HTTP_REMOTE_USER" request env var' do
          let(:env) { { 'HTTP_REMOTE_USER' => login } }

          it 'returns 401 unauthorized' do
            get '/auth/sso', as: :json, env: env

            expect(response).to have_http_status(:unauthorized)
            expect(json_response).to include('error' => 'Maintenance mode enabled!')
          end
        end

        context 'in "X-Forwarded-User" request header' do
          let(:headers) { { 'X-Forwarded-User' => login } }

          it 'returns 401 unauthorized' do
            get '/auth/sso', as: :json, headers: headers

            expect(response).to have_http_status(:unauthorized)
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
end
