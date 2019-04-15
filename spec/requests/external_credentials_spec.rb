require 'rails_helper'

RSpec.describe 'External Credentials', type: :request do
  let(:admin_user) { create(:admin_user) }

  context 'without authentication' do
    describe '#index' do
      it 'returns 401 unauthorized' do
        get '/api/v1/external_credentials', as: :json

        expect(response).to have_http_status(:unauthorized)
        expect(json_response).to include('error' => 'authentication failed')
      end
    end

    describe '#app_verify' do
      it 'returns 401 unauthorized' do
        post '/api/v1/external_credentials/facebook/app_verify', as: :json

        expect(response).to have_http_status(:unauthorized)
        expect(json_response).to include('error' => 'authentication failed')
      end
    end

    describe '#link_account' do
      it 'returns 401 unauthorized' do
        get '/api/v1/external_credentials/facebook/link_account', as: :json

        expect(response).to have_http_status(:unauthorized)
        expect(json_response).to include('error' => 'authentication failed')
      end
    end

    describe '#callback' do
      it 'returns 401 unauthorized' do
        get '/api/v1/external_credentials/facebook/callback', as: :json

        expect(response).to have_http_status(:unauthorized)
        expect(json_response).to include('error' => 'authentication failed')
      end
    end
  end

  context 'authenticated as admin' do
    before { authenticated_as(admin_user) }

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

            it 'returns 401 unauthorized with internal (Zammad) error' do
              post '/api/v1/external_credentials/facebook/app_verify', as: :json
              expect(response).to have_http_status(:unauthorized)
              expect(json_response).to include('error' => 'Not authorized (user)!')
            end
          end

          context 'with no credentials' do
            it 'returns 200 with internal (Zammad) error' do
              post '/api/v1/external_credentials/facebook/app_verify', as: :json

              expect(response).to have_http_status(:ok)
              expect(json_response).to include('error' => 'No application_id param!')
            end
          end

          context 'with invalid credentials, via request params' do
            it 'returns 200 with remote (Facebook auth) error' do
              VCR.use_cassette('request/external_credentials/facebook/app_verify_invalid_credentials_with_not_created') do
                post '/api/v1/external_credentials/facebook/app_verify', params: invalid_credentials, as: :json
              end

              expect(response).to have_http_status(:ok)
              expect(json_response).to include('error' => 'type: OAuthException, code: 101, message: Error validating application. Cannot get application info due to a system error. [HTTP 400]')
            end
          end

          context 'with invalid credentials, via ExternalCredential record' do
            before { create(:facebook_credential, credentials: invalid_credentials) }

            it 'returns 200 with remote (Facebook auth) error' do
              VCR.use_cassette('request/external_credentials/facebook/app_verify_invalid_credentials_with_created') do
                post '/api/v1/external_credentials/facebook/app_verify', as: :json
              end

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
              expect(json_response).to include('error' => 'No facebook app configured!')
            end
          end

          context 'with invalid credentials, via request params' do
            it 'returns 422 unprocessable entity with internal (Zammad) error' do
              get '/api/v1/external_credentials/facebook/link_account', params: invalid_credentials, as: :json

              expect(response).to have_http_status(:unprocessable_entity)
              expect(json_response).to include('error' => 'No facebook app configured!')
            end
          end

          context 'with invalid credentials, via ExternalCredential record' do
            before { create(:facebook_credential, credentials: invalid_credentials) }

            it 'returns 500 with remote (Facebook auth) error' do
              VCR.use_cassette('request/external_credentials/facebook/link_account_with_invalid_credential') do
                get '/api/v1/external_credentials/facebook/link_account', as: :json
              end

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
              expect(json_response).to include('error' => 'No facebook app configured!')
            end
          end

          context 'with invalid credentials, via request params' do
            it 'returns 422 unprocessable entity with internal (Zammad) error' do
              get '/api/v1/external_credentials/facebook/callback', params: invalid_credentials, as: :json

              expect(response).to have_http_status(:unprocessable_entity)
              expect(json_response).to include('error' => 'No facebook app configured!')
            end
          end

          context 'with invalid credentials, via ExternalCredential record' do
            before { create(:facebook_credential, credentials: invalid_credentials) }

            it 'returns 500 with remote (Facebook auth) error' do
              VCR.use_cassette('request/external_credentials/facebook/callback_invalid_credentials') do
                get '/api/v1/external_credentials/facebook/callback', as: :json
              end

              expect(response).to have_http_status(:internal_server_error)
              expect(json_response).to include('error' => 'type: OAuthException, code: 101, message: Error validating application. Cannot get application info due to a system error. [HTTP 400]')
            end
          end
        end
      end
    end

    context 'for Twitter' do
      let(:invalid_credentials) do
        { consumer_key: 123, consumer_secret: 123, oauth_token: 123, oauth_token_secret: 123 }
      end

      describe '#app_verify' do
        describe 'failure cases' do
          context 'when permission for Twitter channel is deactivated' do
            before { Permission.find_by(name: 'admin.channel_twitter').update(active: false) }

            it 'returns 401 unauthorized with internal (Zammad) error' do
              post '/api/v1/external_credentials/twitter/app_verify', as: :json
              expect(response).to have_http_status(:unauthorized)
              expect(json_response).to include('error' => 'Not authorized (user)!')
            end
          end

          context 'with no credentials' do
            it 'returns 200 with internal (Zammad) error' do
              post '/api/v1/external_credentials/twitter/app_verify', as: :json

              expect(response).to have_http_status(:ok)
              expect(json_response).to include('error' => 'No consumer_key param!')
            end
          end

          context 'with invalid credentials, via request params' do
            it 'returns 200 with remote (Twitter auth) error' do
              VCR.use_cassette('request/external_credentials/twitter/app_verify_invalid_credentials_with_not_created') do
                post '/api/v1/external_credentials/twitter/app_verify', params: invalid_credentials, as: :json
              end

              expect(response).to have_http_status(:ok)
              expect(json_response).to include('error' => '401 Authorization Required')
            end
          end

          context 'with invalid credentials, via existing ExternalCredential record' do
            before { create(:twitter_credential, credentials: invalid_credentials) }

            it 'returns 200 with remote (Twitter auth) error' do
              VCR.use_cassette('request/external_credentials/twitter/app_verify_invalid_credentials_with_created') do
                post '/api/v1/external_credentials/twitter/app_verify', as: :json
              end

              expect(response).to have_http_status(:ok)
              expect(json_response).to include('error' => '401 Authorization Required')
            end
          end
        end
      end

      describe '#link_account' do
        describe 'failure cases' do
          context 'with no credentials' do
            it 'returns 422 unprocessable entity with internal (Zammad) error' do
              get '/api/v1/external_credentials/twitter/link_account', as: :json

              expect(response).to have_http_status(:unprocessable_entity)
              expect(json_response).to include('error' => 'No twitter app configured!')
            end
          end

          context 'with invalid credentials, via request params' do
            it 'returns 422 unprocessable entity with internal (Zammad) error' do
              get '/api/v1/external_credentials/twitter/link_account', params: invalid_credentials, as: :json

              expect(response).to have_http_status(:unprocessable_entity)
              expect(json_response).to include('error' => 'No twitter app configured!')
            end
          end

          context 'with invalid credentials, via ExternalCredential record' do
            before { create(:twitter_credential, credentials: invalid_credentials) }

            it 'returns 500 with remote (Twitter auth) error' do
              VCR.use_cassette('request/external_credentials/twitter/link_account_with_invalid_credential') do
                get '/api/v1/external_credentials/twitter/link_account', as: :json
              end

              expect(response).to have_http_status(:internal_server_error)
              expect(json_response).to include('error' => '401 Authorization Required')
            end
          end
        end
      end

      describe '#callback' do
        describe 'failure cases' do
          context 'with no credentials' do
            it 'returns 422 unprocessable entity with internal (Zammad) error' do
              get '/api/v1/external_credentials/twitter/callback', as: :json

              expect(response).to have_http_status(:unprocessable_entity)
              expect(json_response).to include('error' => 'No twitter app configured!')
            end
          end

          context 'with invalid credentials, via request params' do
            it 'returns 422 unprocessable entity with internal (Zammad) error' do
              get '/api/v1/external_credentials/twitter/callback', params: invalid_credentials, as: :json

              expect(response).to have_http_status(:unprocessable_entity)
              expect(json_response).to include('error' => 'No twitter app configured!')
            end
          end

          context 'with invalid credentials, via ExternalCredential record' do
            before { create(:twitter_credential, credentials: invalid_credentials) }

            it 'returns 422 unprocessable entity with internal (Zammad) error' do
              get '/api/v1/external_credentials/twitter/callback', as: :json

              expect(response).to have_http_status(:unprocessable_entity)
              expect(json_response).to include('error' => 'No request_token for session found!')
            end
          end
        end
      end
    end
  end
end
