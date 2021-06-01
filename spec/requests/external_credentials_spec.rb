# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

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
              expect(json_response).to include('error' => 'No application_id param!')
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

            it 'returns 500 with remote (Facebook auth) error', :use_vcr do
              get '/api/v1/external_credentials/facebook/callback', as: :json

              expect(response).to have_http_status(:internal_server_error)
              expect(json_response).to include('error' => 'type: OAuthException, code: 101, message: Error validating application. Cannot get application info due to a system error. [HTTP 400]')
            end
          end
        end
      end
    end

    context 'for Twitter', :use_vcr do
      shared_context 'for callback URL configuration' do
        # NOTE: When recording a new VCR cassette for these tests,
        # the URL below must match the callback URL
        # registered with developer.twitter.com.
        before do
          Setting.set('http_type', 'https')
          Setting.set('fqdn', 'zammad.example.com')
        end
      end

      shared_examples 'for failure cases' do
        it 'responds with the appropriate status and error message' do
          send(*endpoint, as: :json, params: try(:params) || {})

          expect(response).to have_http_status(status)
          expect(json_response).to include('error' => error_message)
        end
      end

      let(:valid_credentials) { attributes_for(:twitter_credential)[:credentials] }
      let(:invalid_credentials) { attributes_for(:twitter_credential, :invalid)[:credentials] }

      describe 'POST /api/v1/external_credentials/twitter/app_verify' do
        let(:endpoint) { [:post, '/api/v1/external_credentials/twitter/app_verify'] }

        context 'when permission for Twitter channel is deactivated' do
          before { Permission.find_by(name: 'admin.channel_twitter').update(active: false) }

          include_examples 'for failure cases' do
            let(:status) { :forbidden }
            let(:error_message) { 'Not authorized (user)!' }
          end
        end

        context 'with no credentials' do
          include_examples 'for failure cases' do
            let(:status) { :ok }
            let(:error_message) { 'No consumer_key param!' }
          end
        end

        context 'with invalid credential params' do
          let(:params) { invalid_credentials }

          include_examples 'for failure cases' do
            let(:status) { :ok }
            let(:error_message) { <<~ERR.chomp }
              401 Authorization Required (Invalid credentials may be to blame.)
            ERR
          end
        end

        context 'with valid credential params but misconfigured callback URL' do
          let(:params) { valid_credentials }

          include_examples 'for failure cases' do
            let(:status) { :ok }
            let(:error_message) { <<~ERR.chomp }
              403 Forbidden (Your app's callback URL configuration on developer.twitter.com may be to blame.)
            ERR
          end
        end

        context 'with valid credential params and callback URL but no dev env registered' do
          let(:params) { valid_credentials }

          include_context 'for callback URL configuration'
          include_examples 'for failure cases' do
            let(:status) { :ok }
            let(:error_message) { <<~ERR.chomp }
              Forbidden. Are you sure you created a development environment on developer.twitter.com?
            ERR
          end
        end

        context 'with valid credential params and callback URL but wrong dev env label' do
          let(:params) { valid_credentials.merge(env: 'foo') }

          include_context 'for callback URL configuration'
          include_examples 'for failure cases' do
            let(:status) { :ok }
            let(:error_message) { <<~ERR.chomp }
              Dev Environment Label invalid. Please use an existing one ["zammad"], or create a new one.
            ERR
          end
        end

        context 'with valid credential params, callback URL, and dev env label' do
          let(:env_name) { valid_credentials[:env] }

          include_context 'for callback URL configuration'

          shared_examples 'for successful webhook connection' do
            let(:webhook_id) { '1241980494134145024' }

            it 'responds 200 OK with the new webhook ID' do
              send(*endpoint, as: :json, params: valid_credentials)

              expect(response).to have_http_status(:ok)
              expect(json_response).to match('attributes' => hash_including('webhook_id' => webhook_id))
            end
          end

          context 'with no existing webhooks' do
            let(:webhook_url) { "#{Setting.get('http_type')}://#{Setting.get('fqdn')}#{Rails.configuration.api_path}/channels_twitter_webhook" }

            include_examples 'for successful webhook connection'

            it 'registers a new webhook' do
              send(*endpoint, as: :json, params: valid_credentials)

              expect(WebMock)
                .to have_requested(:post, "https://api.twitter.com/1.1/account_activity/all/#{env_name}/webhooks.json")
                .with(body: "url=#{CGI.escape(webhook_url)}" )
            end
          end

          context 'with an existing webhook registered to another app' do
            include_examples 'for successful webhook connection'

            it 'deletes all existing webhooks first' do
              send(*endpoint, as: :json, params: valid_credentials)

              expect(WebMock)
                .to have_requested(:delete, "https://api.twitter.com/1.1/account_activity/all/#{env_name}/webhooks/1241981813595049984.json")
            end
          end

          context 'with an existing, invalid webhook registered to Zammad' do
            include_examples 'for successful webhook connection'

            it 'revalidates by manually triggering a challenge-response check' do
              send(*endpoint, as: :json, params: valid_credentials)

              expect(WebMock)
                .to have_requested(:put, "https://api.twitter.com/1.1/account_activity/all/#{env_name}/webhooks/1241980494134145024.json")
            end
          end

          context 'with an existing, valid webhook registered to Zammad' do
            include_examples 'for successful webhook connection'

            it 'uses the existing webhook' do
              send(*endpoint, as: :json, params: valid_credentials)

              expect(WebMock)
                .not_to have_requested(:post, "https://api.twitter.com/1.1/account_activity/all/#{env_name}/webhooks.json")
            end
          end
        end
      end

      describe 'GET /api/v1/external_credentials/twitter/link_account' do
        let(:endpoint) { [:get, '/api/v1/external_credentials/twitter/link_account'] }

        context 'with no Twitter app' do
          include_examples 'for failure cases' do
            let(:status) { :unprocessable_entity }
            let(:error_message) { 'No twitter app configured!' }
          end
        end

        context 'with invalid Twitter app (configured with invalid credentials)' do
          let!(:twitter_credential) { create(:twitter_credential, :invalid) }

          include_examples 'for failure cases' do
            let(:status) { :internal_server_error }
            let(:error_message) { <<~ERR.chomp }
              401 Authorization Required (Invalid credentials may be to blame.)
            ERR
          end
        end

        context 'with a valid Twitter app but misconfigured callback URL' do
          let!(:twitter_credential) { create(:twitter_credential) }

          include_examples 'for failure cases' do
            let(:status) { :internal_server_error }
            let(:error_message) { <<~ERR.chomp }
              403 Forbidden (Your app's callback URL configuration on developer.twitter.com may be to blame.)
            ERR
          end
        end

        context 'with a valid Twitter app and callback URL' do
          let!(:twitter_credential) { create(:twitter_credential) }

          include_context 'for callback URL configuration'

          it 'requests OAuth request token from Twitter API' do
            send(*endpoint, as: :json)

            expect(WebMock)
              .to have_requested(:post, 'https://api.twitter.com/oauth/request_token')
              .with(headers: { 'Authorization' => %r{oauth_consumer_key="#{twitter_credential.credentials[:consumer_key]}"} } )
          end

          it 'redirects to Twitter authorization URL' do
            send(*endpoint, as: :json)

            expect(response).to redirect_to(%r{^https://api.twitter.com/oauth/authorize\?oauth_token=\w+$})
          end

          it 'saves request token to session hash' do
            send(*endpoint, as: :json)

            expect(session[:request_token]).to be_a(OAuth::RequestToken)
          end
        end
      end

      describe 'GET /api/v1/external_credentials/twitter/callback' do
        let(:endpoint) { [:get, '/api/v1/external_credentials/twitter/callback'] }

        context 'with no Twitter app' do
          include_examples 'for failure cases' do
            let(:status) { :unprocessable_entity }
            let(:error_message) { 'No twitter app configured!' }
          end
        end

        context 'with valid Twitter app but no request token' do
          let!(:twitter_credential) { create(:twitter_credential) }

          include_examples 'for failure cases' do
            let(:status) { :unprocessable_entity }
            let(:error_message) { 'No request_token for session found!' }
          end
        end

        context 'with valid Twitter app and request token but non-matching OAuth token (via params)' do
          include_context 'for callback URL configuration'

          let!(:twitter_credential) { create(:twitter_credential) }

          before { get '/api/v1/external_credentials/twitter/link_account', as: :json }

          include_examples 'for failure cases' do
            let(:status) { :unprocessable_entity }
            let(:error_message) { 'Invalid oauth_token given!' }
          end
        end

        # NOTE: Want to delete/regenerate the VCR cassettes for these examples?
        # It's gonna be messy--each one is actually two cassettes merged into one.
        #
        # Why? The OAuth flow can't be fully reproduced in a request spec:
        #
        # 1. User clicks "Add Twitter account" in Zammad.
        #    Zammad asks Twitter for request token, saves it to session,
        #    and redirects user to Twitter.
        # 2. User clicks "Authorize app" on Twitter.
        #    Twitter generates temporary OAuth credentials
        #    and redirects user back to this endpoint (with creds in URL query string).
        # 3. Zammad asks Twitter for an access token
        #    (using request token from Step 1 + OAuth creds from Step 2).
        #
        # In these tests (Step 2), the user hits this endpoint
        # with parameters that ONLY the Twitter OAuth server can generate.
        # In the VCR cassette for Step 3,
        # Zammad sends these parameters back to Twitter for validation.
        # Without valid credentials in Step 2, Step 3 will always fail.
        #
        # Instead, we have to record the VCR cassette in a live development instance
        # and stitch the cassette together with a cassette for Step 1.
        #
        # tl;dr A feature spec might have made more sense here.
        context 'with valid Twitter app, request token, and matching OAuth token (via params)' do
          include_context 'for callback URL configuration'

          let!(:twitter_credential) { create(:twitter_credential) }

          # For illustrative purposes only.
          # These parameters cannot be used to record a new VCR cassette (see note above).
          let(:params) { { oauth_token: oauth_token, oauth_verifier: oauth_verifier } }
          let(:oauth_token) { 'DyhnyQAAAAAA9CNXAAABcSxAexs' }
          let(:oauth_verifier) { '15DOeRkjP4JkOSVqULkTKA1SCuIPP105' }

          before { get '/api/v1/external_credentials/twitter/link_account', as: :json }

          context 'if Twitter account has already been added' do
            let!(:channel) { create(:twitter_channel, custom_options: channel_options) }
            let(:channel_options) do
              {
                user: {
                  id:          '1205290247124217856',
                  screen_name: 'pennbrooke1',
                }
              }
            end

            it 'uses the existing channel' do
              expect { send(*endpoint, as: :json, params: params) }
                .not_to change(Channel, :count)
            end

            it 'updates channel properties' do
              expect { send(*endpoint, as: :json, params: params) }
                .to change { channel.reload.options[:user][:name] }
                .and change { channel.reload.options[:auth][:external_credential_id] }
                .and change { channel.reload.options[:auth][:oauth_token] }
                .and change { channel.reload.options[:auth][:oauth_token_secret] }
            end

            it 'subscribes to webhooks' do
              send(*endpoint, as: :json, params: params)

              expect(WebMock)
                .to have_requested(:post, "https://api.twitter.com/1.1/account_activity/all/#{twitter_credential.credentials[:env]}/subscriptions.json")

              expect(channel.reload.options['subscribed_to_webhook_id'])
                .to eq(twitter_credential.credentials[:webhook_id])
            end
          end

          it 'creates a new channel' do
            expect { send(*endpoint, as: :json, params: params) }
              .to change(Channel, :count).by(1)

            expect(Channel.last.options)
              .to include('adapter' => 'twitter')
              .and include('user' => hash_including('id', 'screen_name', 'name'))
              .and include('auth' => hash_including('external_credential_id', 'oauth_token', 'oauth_token_secret'))
          end

          it 'redirects to the newly created channel' do
            send(*endpoint, as: :json, params: params)

            expect(response).to redirect_to(%r{/#channels/twitter/#{Channel.last.id}$})
          end

          it 'clears the :request_token session variable' do
            send(*endpoint, as: :json, params: params)

            expect(session[:request_token]).to be(nil)
          end

          it 'subscribes to webhooks' do
            send(*endpoint, as: :json, params: params)

            expect(WebMock)
              .to have_requested(:post, "https://api.twitter.com/1.1/account_activity/all/#{twitter_credential.credentials[:env]}/subscriptions.json")

            expect(Channel.last.options['subscribed_to_webhook_id'])
              .to eq(twitter_credential.credentials[:webhook_id])
          end
        end
      end
    end
  end
end
