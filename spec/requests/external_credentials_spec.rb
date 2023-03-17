# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'External Credentials', type: :request do
  let(:admin) { create(:admin) }

  context 'without authentication' do
    describe '#index' do
      it 'returns 403 Forbidden' do
        get '/api/v1/external_credentials', as: :json

        expect(response).to have_http_status(:forbidden)
        expect(json_response).to include('error' => 'Authentication required')
      end
    end

    describe '#app_verify' do
      it 'returns 403 Forbidden' do
        post '/api/v1/external_credentials/facebook/app_verify', as: :json

        expect(response).to have_http_status(:forbidden)
        expect(json_response).to include('error' => 'Authentication required')
      end
    end

    describe '#link_account' do
      it 'returns 403 Forbidden' do
        get '/api/v1/external_credentials/facebook/link_account', as: :json

        expect(response).to have_http_status(:forbidden)
        expect(json_response).to include('error' => 'Authentication required')
      end
    end

    describe '#callback' do
      it 'returns 403 Forbidden' do
        get '/api/v1/external_credentials/facebook/callback', as: :json

        expect(response).to have_http_status(:forbidden)
        expect(json_response).to include('error' => 'Authentication required')
      end
    end
  end

  context 'authenticated as admin' do
    before { authenticated_as(admin, via: :browser) }

    describe '#index' do
      it 'responds with an array of ExternalCredential records' do
        get '/api/v1/external_credentials', as: :json

        expect(response).to have_http_status(:ok)
        expect(json_response).to eq([])
      end

      context 'with expand=true URL parameters' do
        it 'responds with an array of ExternalCredential records and their association data' do
          get '/api/v1/external_credentials?expand=true', as: :json

          expect(response).to have_http_status(:ok)
          expect(json_response).to eq([])
        end
      end
    end

    context 'for Facebook' do
      let(:invalid_credentials) do
        { application_id: 123, application_secret: 123 }
      end

      describe '#app_verify' do
        describe 'failure cases' do
          context 'when permission for Facebook channel is deactivated' do
            before { Permission.find_by(name: 'admin.channel_facebook').update(active: false) }

            it 'returns 403 Forbidden with internal (Zammad) error' do
              post '/api/v1/external_credentials/facebook/app_verify', as: :json
              expect(response).to have_http_status(:forbidden)
              expect(json_response).to include('error' => 'Not authorized (user)!')
            end
          end

          context 'with no credentials' do
            it 'returns 200 with internal (Zammad) error' do
              post '/api/v1/external_credentials/facebook/app_verify', as: :json

              expect(response).to have_http_status(:ok)
              expect(json_response).to include('error' => "The required parameter 'application_id' is missing.")
            end
          end

          context 'with invalid credentials, via request params' do
            it 'returns 200 with remote (Facebook auth) error', :use_vcr do
              post '/api/v1/external_credentials/facebook/app_verify', params: invalid_credentials, as: :json

              expect(response).to have_http_status(:ok)
              expect(json_response).to include('error' => 'type: OAuthException, code: 101, message: Error validating application. Cannot get application info due to a system error. [HTTP 400]')
            end
          end

          context 'with invalid credentials, via ExternalCredential record' do
            before { create(:facebook_credential, credentials: invalid_credentials) }

            it 'returns 200 with remote (Facebook auth) error', :use_vcr do
              post '/api/v1/external_credentials/facebook/app_verify', as: :json

              expect(response).to have_http_status(:ok)
              expect(json_response).to include('error' => 'type: OAuthException, code: 101, message: Error validating application. Cannot get application info due to a system error. [HTTP 400]')
            end
          end
        end
      end

      describe '#link_account' do
        describe 'failure cases' do
          context 'with no credentials' do
            it 'returns 422 unprocessable entity with internal (Zammad) error' do
              get '/api/v1/external_credentials/facebook/link_account', as: :json

              expect(response).to have_http_status(:unprocessable_entity)
              expect(json_response).to include('error' => 'No Facebook app configured!')
            end
          end

          context 'with invalid credentials, via request params' do
            it 'returns 422 unprocessable entity with internal (Zammad) error' do
              get '/api/v1/external_credentials/facebook/link_account', params: invalid_credentials, as: :json

              expect(response).to have_http_status(:unprocessable_entity)
              expect(json_response).to include('error' => 'No Facebook app configured!')
            end
          end

          context 'with invalid credentials, via ExternalCredential record' do
            before { create(:facebook_credential, credentials: invalid_credentials) }

            it 'returns 500 with remote (Facebook auth) error', :use_vcr do
              get '/api/v1/external_credentials/facebook/link_account', as: :json

              expect(response).to have_http_status(:internal_server_error)
              expect(json_response).to include('error' => 'type: OAuthException, code: 101, message: Error validating application. Cannot get application info due to a system error. [HTTP 400]')
            end
          end
        end
      end

      describe '#callback' do
        describe 'failure cases' do
          context 'with no credentials' do
            it 'returns 422 unprocessable entity with internal (Zammad) error' do
              get '/api/v1/external_credentials/facebook/callback', as: :json

              expect(response).to have_http_status(:unprocessable_entity)
              expect(json_response).to include('error' => 'No Facebook app configured!')
            end
          end

          context 'with invalid credentials, via request params' do
            it 'returns 422 unprocessable entity with internal (Zammad) error' do
              get '/api/v1/external_credentials/facebook/callback', params: invalid_credentials, as: :json

              expect(response).to have_http_status(:unprocessable_entity)
              expect(json_response).to include('error' => 'No Facebook app configured!')
            end
          end

          context 'with invalid credentials, via ExternalCredential record' do
            before { create(:facebook_credential, credentials: invalid_credentials) }

            it 'returns 500 with remote (Facebook auth) error', :use_vcr do
              get '/api/v1/external_credentials/facebook/callback', as: :json

              expect(response).to have_http_status(:internal_server_error)
              expect(json_response).to include('error' => 'type: OAuthException, code: 101, message: Error validating application. Cannot get application info due to a system error. [HTTP 400]')
            end
          end
        end
      end
    end
  end
end
