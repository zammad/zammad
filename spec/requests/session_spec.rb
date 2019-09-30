require 'rails_helper'

RSpec.describe 'Sessions endpoints', type: :request do

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
