# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'External Credentials > Twitter', required_envs: %w[TWITTER_CONSUMER_KEY TWITTER_CONSUMER_SECRET TWITTER_OAUTH_TOKEN TWITTER_OAUTH_TOKEN_SECRET TWITTER_DEV_ENVIRONMENT], type: :request do
  let(:admin) { create(:admin) }

  let(:valid_credentials)   { attributes_for(:twitter_credential)[:credentials] }
  let(:invalid_credentials) { attributes_for(:twitter_credential, :invalid)[:credentials] }

  let(:webhook_url) { "#{Setting.get('http_type')}://#{Setting.get('fqdn')}#{Rails.configuration.api_path}/channels_twitter_webhook" }

  def body_forbidden
    {
      errors: [
        {
          code:    403,
          message: 'Forbidden.',
        },
      ],
    }.to_json
  end

  def headers
    { content_type: 'application/json; charset=utf-8' }
  end

  def oauth_request_token
    stub_post('https://api.twitter.com/oauth/request_token').to_return(
      status: 200,
      body:   'oauth_token=DY8E9gAAAAABCFc9AAABcP4JGzI&oauth_token_secret=gAR1aD2RGw3klpbxNtMuwvALohChdLDR&oauth_callback_confirmed=true',
    )
  end

  def oauth_request_token_unauthorized
    stub_post('https://api.twitter.com/oauth/request_token').to_return(
      status: [ 401, 'Unauthorized' ],
      body:   '',
    )
  end

  def oauth_request_token_forbidden
    stub_post('https://api.twitter.com/oauth/request_token').to_return(
      status: [ 403, 'Forbidden' ],
      body:   '',
    )
  end

  def oauth_access_token
    stub_post('https://api.twitter.com/oauth/access_token').to_return(
      body: 'oauth_token=DY8E9gAAAAABCFc9AAABcP4JGzI&oauth_token_secret=15DOeRkjP4JkOSVqULkTKA1SCuIPP105&user_id=1408314039470538752&screen_name=APITesting001'
    )
  end

  def webhook_data(app, valid)
    {
      id:         '1234567890',
      url:        "https://#{app}.example.com/api/v1/channels_twitter_webhook",
      valid:      valid,
      created_at: '2022-10-11T07:30:00Z',
    }
  end

  def webhooks_forbidden
    stub_get('https://api.twitter.com/1.1/account_activity/all/webhooks.json').to_return(
      status:  403,
      body:    body_forbidden,
      headers: headers,
    )
  end

  def webhooks_ok
    stub_get('https://api.twitter.com/1.1/account_activity/all/webhooks.json').to_return(
      status:  200,
      body:    {
        environments: [
          environment_name: 'Integration',
          webhooks:         [ webhook_data('zammad', true) ],
        ],
      }.to_json,
      headers: headers,
    )
  end

  def webhooks_env_empty(env: 'zammad')
    stub_get("https://api.twitter.com/1.1/account_activity/all/#{env}/webhooks.json").to_return(
      status:  200,
      body:    [].to_json,
      headers: headers,
    )
  end

  def webhooks_env_forbidden(env: 'zammad')
    stub_get("https://api.twitter.com/1.1/account_activity/all/#{env}/webhooks.json").to_return(
      status:  403,
      body:    body_forbidden,
      headers: headers,
    )
  end

  def webhooks_env_another_app
    webhooks_env_ok(valid: true, app: 'another-app')
  end

  def webhooks_env_invalid
    webhooks_env_ok(valid: false)
  end

  def webhooks_env_ok(valid: true, app: 'zammad')
    stub_get('https://api.twitter.com/1.1/account_activity/all/zammad/webhooks.json').to_return(
      status:  200,
      body:    [ webhook_data(app, valid) ].to_json,
      headers: headers,
    )
  end

  def register_webhook
    stub_post('https://api.twitter.com/1.1/account_activity/all/zammad/webhooks.json').to_return(
      status:  200,
      body:    webhook_data('zammad', true).to_json,
      headers: headers,
    )
  end

  def delete_webhook
    stub_delete('https://api.twitter.com/1.1/account_activity/all/zammad/webhooks/1234567890.json').to_return(
      status: 204,
      body:   nil,
    )
  end

  def crc_webhook
    stub_put('https://api.twitter.com/1.1/account_activity/all/zammad/webhooks/1234567890.json').to_return(
      status: 204,
      body:   nil,
    )
  end

  def account_verify_credentials
    stub_get('https://api.twitter.com/1.1/account/verify_credentials.json').to_return(
      body:    Rails.root.join('spec/fixtures/files/external_credentials/twitter/zammad_testing.json').read,
      headers: { content_type: 'application/json; charset=utf-8' },
    )
  end

  def env_subscriptions(env: 'zammad')
    stub_post("https://api.twitter.com/1.1/account_activity/all/#{env}/subscriptions.json").to_return(
      status:  204,
      headers: { content_type: 'application/json; charset=utf-8' },
    )
  end

  describe 'POST /api/v1/external_credentials/twitter/app_verify' do
    before do
      authenticated_as(admin, via: :browser)
    end

    context 'when permission for Twitter channel is deactivated' do
      before do
        Permission.find_by(name: 'admin.channel_twitter').update(active: false)
      end

      it 'blocks the request', :aggregate_failures do
        post '/api/v1/external_credentials/twitter/app_verify', params: {}, as: :json

        expect(response).to have_http_status(:forbidden)
        expect(json_response).to include('error' => 'Not authorized (user)!')
      end
    end

    context 'with no credentials' do
      it 'blocks the request', :aggregate_failures do
        post '/api/v1/external_credentials/twitter/app_verify', params: {}, as: :json

        expect(response).to have_http_status(:ok)
        expect(json_response).to include('error' => "The required parameter 'consumer_key' is missing.")
      end
    end

    context 'with invalid credential params' do
      before do
        oauth_request_token_unauthorized
      end

      it 'blocks the request', :aggregate_failures do
        post '/api/v1/external_credentials/twitter/app_verify', params: invalid_credentials, as: :json

        expect(response).to have_http_status(:ok)
        expect(json_response).to include('error' => '401 Unauthorized (Invalid credentials may be to blame.)')
      end
    end

    context 'with valid credential params but misconfigured callback URL' do
      before do
        oauth_request_token_forbidden
      end

      it 'blocks the request', :aggregate_failures do
        post '/api/v1/external_credentials/twitter/app_verify', params: valid_credentials, as: :json

        expect(response).to have_http_status(:ok)
        expect(json_response).to include('error' => "403 Forbidden (Your app's callback URL configuration on developer.twitter.com may be to blame.)")
      end
    end

    context 'with valid credential params and callback URL but no dev env registered' do
      before do
        oauth_request_token
        webhooks_forbidden
        webhooks_env_forbidden
      end

      it 'blocks the request', :aggregate_failures do
        post '/api/v1/external_credentials/twitter/app_verify', params: valid_credentials, as: :json

        expect(response).to have_http_status(:ok)
        expect(json_response).to include('error' => 'Forbidden. Are you sure you created a development environment on developer.twitter.com?')
      end
    end

    context 'with valid credential params and callback URL but wrong dev env label' do
      before do
        oauth_request_token
        webhooks_ok
        webhooks_env_forbidden(env: 'foo')
      end

      it 'blocks the request', :aggregate_failures do
        post '/api/v1/external_credentials/twitter/app_verify', params: valid_credentials.merge(env: 'foo'), as: :json

        expect(response).to have_http_status(:ok)
        expect(json_response).to include('error' => "Dev Environment Label invalid. Please use an existing one [\"#{ENV.fetch('TWITTER_DEV_ENVIRONMENT', 'Integration')}\"], or create a new one.")
      end
    end

    context 'with valid credential params, callback URL, and dev env label' do
      before do
        oauth_request_token

        Setting.set('http_type', 'https')
        Setting.set('fqdn', 'zammad.example.com')
      end

      context 'with no existing webhooks' do
        before do
          webhooks_env_empty
          register_webhook
        end

        it 'registers a new webhook', :aggregate_failures do
          post '/api/v1/external_credentials/twitter/app_verify', params: valid_credentials, as: :json

          expect(a_post('https://api.twitter.com/1.1/account_activity/all/zammad/webhooks.json').with(body: "url=#{CGI.escape(webhook_url)}")).to have_been_made.once

          expect(response).to have_http_status(:ok)
          expect(json_response).to match('attributes' => hash_including('webhook_id' => '1234567890'))
        end
      end

      context 'with an existing webhook registered to another app' do
        before do
          webhooks_env_another_app
          delete_webhook
          register_webhook
        end

        it 'deletes all existing webhooks and registers a new one', :aggregate_failures do
          post '/api/v1/external_credentials/twitter/app_verify', params: valid_credentials, as: :json

          expect(a_delete('https://api.twitter.com/1.1/account_activity/all/zammad/webhooks/1234567890.json'))
            .to have_been_made.once

          expect(response).to have_http_status(:ok)
          expect(json_response).to match('attributes' => hash_including('webhook_id' => '1234567890'))
        end
      end

      context 'with an existing, invalid webhook registered to Zammad' do
        before do
          webhooks_env_invalid
          crc_webhook
        end

        it 'revalidates by manually triggering a challenge-response check', :aggregate_failures do
          post '/api/v1/external_credentials/twitter/app_verify', params: valid_credentials, as: :json

          expect(a_put('https://api.twitter.com/1.1/account_activity/all/zammad/webhooks/1234567890.json')).to have_been_made.once

          expect(response).to have_http_status(:ok)
          expect(json_response).to match('attributes' => hash_including('webhook_id' => '1234567890'))
        end
      end

      context 'with an existing, valid webhook registered to Zammad' do
        before do
          webhooks_env_ok
        end

        it 'uses the existing webhook' do
          post '/api/v1/external_credentials/twitter/app_verify', params: valid_credentials, as: :json

          expect(a_post('https://api.twitter.com/1.1/account_activity/all/zammad/webhooks.json').with(body: "url=#{CGI.escape(webhook_url)}")).not_to have_been_made
        end
      end
    end
  end

  describe 'GET /api/v1/external_credentials/twitter/link_account' do
    before do
      authenticated_as(admin, via: :browser)
    end

    context 'with no Twitter app' do
      it 'returns an error message', :aggregate_failures do
        get '/api/v1/external_credentials/twitter/link_account', as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response).to include('error' => 'There is no Twitter app configured.')
      end
    end

    context 'with invalid Twitter app (configured with invalid credentials)' do
      before do
        create(:twitter_credential, :invalid)
        oauth_request_token_unauthorized
      end

      it 'returns an error message', :aggregate_failures do
        get '/api/v1/external_credentials/twitter/link_account', as: :json

        expect(response).to have_http_status(:internal_server_error)
        expect(json_response).to include('error' => '401 Unauthorized (Invalid credentials may be to blame.)')
      end
    end

    context 'with a valid Twitter app but misconfigured callback URL' do
      before do
        create(:twitter_credential)
        oauth_request_token_forbidden
      end

      it 'returns an error message', :aggregate_failures do
        get '/api/v1/external_credentials/twitter/link_account', as: :json

        expect(response).to have_http_status(:internal_server_error)
        expect(json_response).to include('error' => "403 Forbidden (Your app's callback URL configuration on developer.twitter.com may be to blame.)")
      end
    end

    context 'with a valid Twitter app and callback URL' do
      let(:twitter_credential) { create(:twitter_credential) }

      before do
        twitter_credential
        oauth_request_token

        Setting.set('http_type', 'https')
        Setting.set('fqdn', 'zammad.example.com')
      end

      it 'returns authorization data in the headers' do
        get '/api/v1/external_credentials/twitter/link_account', as: :json

        expect(
          a_post('https://api.twitter.com/oauth/request_token').with(headers: { 'Authorization' => %r{oauth_consumer_key="#{twitter_credential.credentials[:consumer_key]}"} })
        ).to have_been_made.once
      end

      it 'redirects to Twitter authorization URL' do
        get '/api/v1/external_credentials/twitter/link_account', as: :json

        expect(response).to redirect_to(%r{^https://api.twitter.com/oauth/authorize\?oauth_token=\w+$})
      end

      it 'saves request token to session hash' do
        get '/api/v1/external_credentials/twitter/link_account', as: :json

        expect(session[:request_token]).to be_a(OAuth::RequestToken)
      end
    end
  end

  describe 'GET /api/v1/external_credentials/twitter/callback' do
    before do
      authenticated_as(admin, via: :browser)
    end

    context 'with no Twitter app' do
      it 'returns an error message', :aggregate_failures do
        get '/api/v1/external_credentials/twitter/callback', as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response).to include('error' => 'There is no Twitter app configured.')
      end
    end

    context 'with valid Twitter app but no request token' do
      before do
        create(:twitter_credential)
      end

      it 'returns an error message', :aggregate_failures do
        get '/api/v1/external_credentials/twitter/callback', as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response).to include('error' => "The required parameter 'request_token' is missing.")
      end
    end

    context 'with valid Twitter app and request token but non-matching OAuth token (via params)' do
      before do
        create(:twitter_credential)

        Setting.set('http_type', 'https')
        Setting.set('fqdn', 'zammad.example.com')

        oauth_request_token
        get '/api/v1/external_credentials/twitter/link_account', as: :json, headers: { 'X-Forwarded-Proto' => 'https' }
      end

      it 'returns an error message', :aggregate_failures do
        get '/api/v1/external_credentials/twitter/callback', as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response).to include('error' => "The provided 'oauth_token' is invalid.")
      end
    end

    context 'with valid Twitter app, request token, and matching OAuth token (via params)' do
      let(:twitter_credential) { create(:twitter_credential) }
      let(:params)             { { oauth_token: 'DY8E9gAAAAABCFc9AAABcP4JGzI', oauth_verifier: '15DOeRkjP4JkOSVqULkTKA1SCuIPP105' } }

      before do
        twitter_credential
        Setting.set('http_type', 'https')
        Setting.set('fqdn', 'zammad.example.com')

        oauth_request_token
        get '/api/v1/external_credentials/twitter/link_account', as: :json, headers: { 'X-Forwarded-Proto' => 'https' }

        oauth_access_token
        account_verify_credentials
        env_subscriptions
      end

      it 'creates a new channel', :aggregate_failures do
        expect { get '/api/v1/external_credentials/twitter/callback', as: :json, params: params, headers: { 'X-Forwarded-Proto' => 'https' } }.to change(Channel, :count).by(1)

        expect(Channel.last.options).to include('adapter' => 'twitter')
          .and include('user' => hash_including('id', 'screen_name', 'name'))
          .and include('auth' => hash_including('external_credential_id', 'oauth_token', 'oauth_token_secret'))
      end

      it 'redirects to the newly created channel', :aggregate_failures do
        expect { get '/api/v1/external_credentials/twitter/callback', as: :json, params: params, headers: { 'X-Forwarded-Proto' => 'https' } }.to change(Channel, :count).by(1)

        expect(response).to redirect_to(%r{/#channels/twitter/#{Channel.last.id}$})
      end

      it 'clears the :request_token session variable', :aggregate_failures do
        expect { get '/api/v1/external_credentials/twitter/callback', as: :json, params: params, headers: { 'X-Forwarded-Proto' => 'https' } }.to change(Channel, :count).by(1)

        expect(session[:request_token]).to be_nil
      end

      it 'subscribes to webhooks', :aggregate_failures do
        expect { get '/api/v1/external_credentials/twitter/callback', as: :json, params: params, headers: { 'X-Forwarded-Proto' => 'https' } }.to change(Channel, :count).by(1)

        expect(
          a_post("https://api.twitter.com/1.1/account_activity/all/#{twitter_credential.credentials[:env]}/subscriptions.json").with(body: {})
        ).to have_been_made.once

        expect(Channel.last.options['subscribed_to_webhook_id']).to eq(twitter_credential.credentials[:webhook_id])
      end

      context 'when Twitter account has already been added' do
        let(:channel) { create(:twitter_channel) }

        before do
          channel
        end

        it 'uses the existing channel' do
          expect do
            get '/api/v1/external_credentials/twitter/callback', as: :json, params: params, headers: { 'X-Forwarded-Proto' => 'https' }
          end.not_to change(Channel, :count)
        end

        it 'updates channel properties' do
          expect { get '/api/v1/external_credentials/twitter/callback', as: :json, params: params, headers: { 'X-Forwarded-Proto' => 'https' } }.to change { channel.reload.updated_at }
            .and change { channel.reload.options[:auth][:external_credential_id] }
            .and change { channel.reload.options[:auth][:oauth_token] }
            .and change { channel.reload.options[:auth][:oauth_token_secret] }
        end

        it 'subscribes to webhooks', :aggregate_failures do
          get '/api/v1/external_credentials/twitter/callback', as: :json, params: params, headers: { 'X-Forwarded-Proto' => 'https' }

          expect(
            a_post("https://api.twitter.com/1.1/account_activity/all/#{twitter_credential.credentials[:env]}/subscriptions.json").with(body: {})
          ).to have_been_made.once
          expect(channel.reload.options['subscribed_to_webhook_id']).to eq(twitter_credential.credentials[:webhook_id])
        end
      end
    end
  end
end
