# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Microsoft Graph Email Notification', aggregate_failures: true, authenticated_as: :admin, type: :request do
  let(:admin) { create(:admin) }

  describe 'POST /api/v1/channels_email_notification (microsoft_graph_outbound)' do
    it 'returns a redirect to the OAuth URL' do
      post '/api/v1/channels_email_notification', params: { adapter: 'microsoft_graph_outbound' }, as: :json

      expect(response).to have_http_status(:ok)
      expect(json_response).to include(
        'result' => 'redirect',
        'url'    => include('external_credentials/microsoft_graph/link_account', 'notification=true'),
      )
    end

    context 'with shared mailbox' do
      it 'passes shared_mailbox in the redirect URL' do
        post '/api/v1/channels_email_notification', params: {
          adapter: 'microsoft_graph_outbound',
          options: { shared_mailbox: 'shared@example.com' },
        }, as: :json

        expect(json_response['url']).to include('shared_mailbox=shared%40example.com')
      end
    end
  end

  describe 'GET /api/v1/external_credentials/microsoft_graph/link_account (notification)' do
    before do
      create(:external_credential, name: 'microsoft_graph', credentials: {
               client_id:     'test_client_id',
               client_secret: 'test_client_secret',
               client_tenant: 'common',
             })
    end

    it 'stores notification flag in session and redirects to Microsoft OAuth' do
      get '/api/v1/external_credentials/microsoft_graph/link_account', params: { notification: 'true' }

      expect(response).to have_http_status(:found)
      expect(response.headers['Location']).to include('login.microsoftonline.com')
    end
  end

  describe 'GET /api/v1/external_credentials/microsoft_graph/callback (notification)' do
    let(:state_token) { SecureRandom.urlsafe_base64 }

    let(:token_response) do
      {
        access_token:  'new_access_token',
        refresh_token: 'new_refresh_token',
        expires_in:    3600,
        scope:         'offline_access openid profile email mail.send',
        token_type:    'Bearer',
        id_token:      jwt_id_token,
      }
    end

    let(:jwt_id_token) do
      payload = { preferred_username: 'user@example.com' }
      "header.#{Base64.urlsafe_encode64(payload.to_json)}.signature"
    end

    let(:shared_mailbox) { nil }

    before do
      create(:external_credential, name: 'microsoft_graph', credentials: {
               client_id:     'test_client_id',
               client_secret: 'test_client_secret',
               client_tenant: 'common',
             })

      # Simulate session state from link_account
      allow_any_instance_of(ActionDispatch::Request).to receive(:session).and_return(
        {
          request_token:  state_token,
          notification:   true,
          shared_mailbox: shared_mailbox,
        }.with_indifferent_access,
      )

      allow(ExternalCredential::MicrosoftGraph).to receive(:authorize_tokens).and_return(token_response)
    end

    it 'exchanges code for tokens and updates the notification channel' do
      get '/api/v1/external_credentials/microsoft_graph/callback', params: { code: 'auth_code', state: state_token }

      expect(response).to have_http_status(:found)
      expect(response.headers['Location']).to include('#channels/email')

      channel = Channel.where(area: 'Email::Notification').find do |ch|
        adapter = ch.options.dig(:outbound, :adapter) || ch.options.dig('outbound', 'adapter')
        adapter == 'microsoft_graph_outbound'
      end

      expect(channel).to have_attributes(
        active:  true,
        options: include(
          outbound: include(
            adapter: 'microsoft_graph_outbound',
            options: include(user: 'user@example.com'),
          ),
          auth:     include(
            provider:     'microsoft_graph',
            access_token: 'new_access_token',
          ),
        ),
      )
    end

    context 'with shared mailbox' do
      let(:shared_mailbox) { 'shared@example.com' }

      it 'stores shared mailbox in outbound options' do
        get '/api/v1/external_credentials/microsoft_graph/callback', params: { code: 'auth_code', state: state_token }

        channel = Channel.where(area: 'Email::Notification').find do |ch|
          adapter = ch.options.dig(:outbound, :adapter) || ch.options.dig('outbound', 'adapter')
          adapter == 'microsoft_graph_outbound'
        end

        expect(channel.options.dig(:outbound, :options, :shared_mailbox)).to eq('shared@example.com')
      end
    end

    context 'with invalid state token' do
      it 'raises an error' do
        expect do
          get '/api/v1/external_credentials/microsoft_graph/callback', params: { code: 'auth_code', state: 'wrong_state' }
        end.to raise_error(Exceptions::UnprocessableEntity, %r{Invalid OAuth state})
      end
    end
  end
end
