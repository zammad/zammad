# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'OAuth', type: :request do

  describe 'request handling' do
    let(:client_ids) { %w[first-client-id second-client-id] }

    before do
      # Bypass CSRF protection for OAuth requests
      allow_any_instance_of(ActionController::RequestForgeryProtection).to receive(:valid_authenticity_token?).and_return(true)
    end

    it 'does o365 - start' do
      post '/auth/microsoft_office365'
      expect(response).to have_http_status(:found)
      expect(response.location).to include('https://login.microsoftonline.com/common/oauth2/v2.0/authorize')
      expect(response.location).to include('redirect_uri=http%3A%2F%2Fzammad.example.com%2Fauth%2Fmicrosoft_office365%2Fcallback')
      expect(response.location).to include('scope=openid%20User.Read')
      expect(response.location).not_to include('Contacts.Read')
      expect(response.location).to include('response_type=code')
    end

    it 'does o365 - callback' do
      get '/auth/microsoft_office365/callback?code=1234&state=1234'
      expect(response).to have_http_status(:found)
      expect(response.body).to include('302 Moved')
    end

    it 'does auth failure' do
      get '/auth/failure?message=123&strategy=some_provider'
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include('<title>422: Unprocessable Content</title>')
      expect(response.body).to include('<h1>422: The change you wanted was rejected.</h1>')
      expect(response.body).to include('<div>Message from some_provider: 123</div>')
    end

    it 'uses changed SAML settings without a restart' do
      Setting.set('fqdn', 'first.example.com')
      get '/auth/saml/metadata'
      expect(response.body).to include("entityID='http://first.example.com/auth/saml/metadata'")

      Setting.set('fqdn', 'second.example.com')
      get '/auth/saml/metadata'
      expect(response.body).to include("entityID='http://second.example.com/auth/saml/metadata'")
    end

    it 'uses changed o365 tenant settings without a restart' do
      Setting.set('auth_microsoft_office365_credentials', { 'app_id' => 'o365-id', 'app_tenant' => 'first-tenant' })
      post '/auth/microsoft_office365'
      expect(response.location).to start_with('https://login.microsoftonline.com/first-tenant/oauth2/v2.0/authorize')

      Setting.set('auth_microsoft_office365_credentials', { 'app_id' => 'o365-id', 'app_tenant' => 'second-tenant' })
      post '/auth/microsoft_office365'
      expect(response.location).to start_with('https://login.microsoftonline.com/second-tenant/oauth2/v2.0/authorize')
    end

    {
      facebook:            { setting: 'auth_facebook_credentials',            id_key: 'app_id' },
      github:              { setting: 'auth_github_credentials',              id_key: 'app_id' },
      gitlab:              { setting: 'auth_gitlab_credentials',              id_key: 'app_id', extra: { 'site' => 'https://gitlab.example.com' } },
      google_oauth2:       { setting: 'auth_google_oauth2_credentials',       id_key: 'client_id' },
      linkedin:            { setting: 'auth_linkedin_credentials',            id_key: 'app_id' },
      microsoft_office365: { setting: 'auth_microsoft_office365_credentials', id_key: 'app_id' },
      weibo:               { setting: 'auth_weibo_credentials',               id_key: 'client_id' },
    }.each do |provider, config|
      it "uses the changed #{provider} client ID without a restart" do
        client_ids.each do |client_id|
          Setting.set(config[:setting], { config[:id_key] => client_id, **config.fetch(:extra, {}) })
          post "/auth/#{provider}"
          expect(response.location).to include("client_id=#{client_id}")
        end
      end
    end

    it 'uses changed OIDC settings without a restart' do
      %w[first second].each do |name|
        stub_request(:get, "https://#{name}.idp.example.com/.well-known/openid-configuration").to_return(
          headers: { 'Content-Type' => 'application/json' },
          body:    {
            issuer:                                "https://#{name}.idp.example.com",
            authorization_endpoint:                "https://#{name}.idp.example.com/authorize",
            token_endpoint:                        "https://#{name}.idp.example.com/token",
            jwks_uri:                              "https://#{name}.idp.example.com/jwks",
            response_types_supported:              %w[code],
            subject_types_supported:               %w[public],
            id_token_signing_alg_values_supported: %w[RS256],
          }.to_json,
        )
      end

      client_ids.zip(%w[first second]).each do |client_id, name|
        Setting.set('auth_openid_connect_credentials', { 'identifier' => client_id, 'issuer' => "https://#{name}.idp.example.com" })
        post '/auth/openid_connect'
        expect(response.location).to start_with("https://#{name}.idp.example.com/authorize").and include("client_id=#{client_id}")
      end
    end

    it 'uses changed Twitter settings without a restart' do
      stub_request(:post, 'https://api.twitter.com/oauth/request_token')
        .to_return(body: 'oauth_token=token&oauth_token_secret=secret&oauth_callback_confirmed=true')

      %w[first-key second-key].each do |key|
        Setting.set('auth_twitter_credentials', { 'key' => key, 'secret' => 'secret' })
        post '/auth/twitter'
        expect(a_request(:post, 'https://api.twitter.com/oauth/request_token')
          .with { |request| request.headers['Authorization'].include?("oauth_consumer_key=\"#{key}\"") }).to have_been_made.once
      end
    end
  end

end
