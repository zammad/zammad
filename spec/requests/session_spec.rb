require 'rails_helper'

RSpec.describe 'Sessions endpoints', type: :request do
  # The frontend sends a device fingerprint in the request parameters during authentication
  # (as part of App.Auth.loginCheck() and App.WebSocket.auth()).
  #
  # Without this parameter, the controller will raise a 422 Unprocessable Entity error
  # (in ApplicationController::HandlesDevices#user_device_log).
  let(:fingerprint) { { fingerprint: 'foo' } }

  describe 'GET /api/v1/signshow (single sign-on)' do
    context 'with invalid user login' do
      let(:login) { User.pluck(:login).max.next }

      context 'in "REMOTE_USER" request env var' do
        let(:env) { { 'REMOTE_USER' => login } }

        it 'returns invalid session response' do
          get '/api/v1/signshow', as: :json, env: env, params: fingerprint

          expect(response).to have_http_status(:ok)
          expect(json_response)
            .to include('error' => 'no valid session')
            .and not_include('session')
        end
      end

      context 'in "HTTP_REMOTE_USER" request env var' do
        let(:env) { { 'HTTP_REMOTE_USER' => login } }

        it 'returns invalid session response' do
          get '/api/v1/signshow', as: :json, env: env, params: fingerprint

          expect(response).to have_http_status(:ok)
          expect(json_response)
            .to include('error' => 'no valid session')
            .and not_include('session')
        end
      end

      context 'in "X-Forwarded-User" request header' do
        let(:headers) { { 'X-Forwarded-User' => login } }

        it 'returns invalid session response' do
          get '/api/v1/signshow', as: :json, headers: headers, params: fingerprint

          expect(response).to have_http_status(:ok)
          expect(json_response)
            .to include('error' => 'no valid session')
            .and not_include('session')
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
            get '/api/v1/signshow', as: :json, env: env, params: fingerprint

            expect(response).to have_http_status(:unauthorized)
            expect(json_response).to include('error' => 'Maintenance mode enabled!')
          end
        end

        context 'in "HTTP_REMOTE_USER" request env var' do
          let(:env) { { 'HTTP_REMOTE_USER' => login } }

          it 'returns 401 unauthorized' do
            get '/api/v1/signshow', as: :json, env: env, params: fingerprint

            expect(response).to have_http_status(:unauthorized)
            expect(json_response).to include('error' => 'Maintenance mode enabled!')
          end
        end

        context 'in "X-Forwarded-User" request header' do
          let(:headers) { { 'X-Forwarded-User' => login } }

          it 'returns 401 unauthorized' do
            get '/api/v1/signshow', as: :json, headers: headers, params: fingerprint

            expect(response).to have_http_status(:unauthorized)
            expect(json_response).to include('error' => 'Maintenance mode enabled!')
          end
        end
      end

      context 'in "REMOTE_USER" request env var' do
        let(:env) { { 'REMOTE_USER' => login } }

        it 'returns a new user-session response' do
          get '/api/v1/signshow', as: :json, env: env, params: fingerprint

          expect(json_response)
            .to include('session' => hash_including('login' => login))
            .and not_include('error')
        end

        it 'sets the :user_id session parameter' do
          expect { get '/api/v1/signshow', as: :json, env: env, params: fingerprint }
            .to change { request&.session&.fetch(:user_id) }.to(user.id)
        end

        it 'sets the :persistent session parameter' do
          expect { get '/api/v1/signshow', as: :json, env: env, params: fingerprint }
            .to change { request&.session&.fetch(:persistent) }.to(true)
        end

        it 'adds an activity stream entry for the user’s session' do
          expect { get '/api/v1/signshow', as: :json, env: env, params: fingerprint }
            .to change(ActivityStream, :count).by(1)
        end
      end

      context 'in "HTTP_REMOTE_USER" request env var' do
        let(:env) { { 'HTTP_REMOTE_USER' => login } }

        it 'returns a new user-session response' do
          get '/api/v1/signshow', as: :json, env: env, params: fingerprint

          expect(json_response)
            .to include('session' => hash_including('login' => login))
            .and not_include('error')
        end

        it 'sets the :user_id session parameter' do
          expect { get '/api/v1/signshow', as: :json, env: env, params: fingerprint }
            .to change { request&.session&.fetch(:user_id) }.to(user.id)
        end

        it 'sets the :persistent session parameter' do
          expect { get '/api/v1/signshow', as: :json, env: env, params: fingerprint }
            .to change { request&.session&.fetch(:persistent) }.to(true)
        end

        it 'adds an activity stream entry for the user’s session' do
          expect { get '/api/v1/signshow', as: :json, env: env, params: fingerprint }
            .to change(ActivityStream, :count).by(1)
        end
      end

      context 'in "X-Forwarded-User" request header' do
        let(:headers) { { 'X-Forwarded-User' => login } }

        it 'returns a new user-session response' do
          get '/api/v1/signshow', as: :json, headers: headers, params: fingerprint

          expect(json_response)
            .to include('session' => hash_including('login' => login))
            .and not_include('error')
        end

        it 'sets the :user_id session parameter on the client' do
          expect { get '/api/v1/signshow', as: :json, headers: headers, params: fingerprint }
            .to change { request&.session&.fetch(:user_id) }.to(user.id)
        end

        it 'sets the :persistent session parameter' do
          expect { get '/api/v1/signshow', as: :json, headers: headers, params: fingerprint }
            .to change { request&.session&.fetch(:persistent) }.to(true)
        end

        it 'adds an activity stream entry for the user’s session' do
          expect { get '/api/v1/signshow', as: :json, headers: headers, params: fingerprint }
            .to change(ActivityStream, :count).by(1)
        end
      end
    end
  end
end
