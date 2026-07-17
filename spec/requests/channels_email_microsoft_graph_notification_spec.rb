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
        id_token:      'fake.id.token',
      }
    end

    let(:shared_mailbox) { nil }

    before do
      create(:external_credential, name: 'microsoft_graph', credentials: {
               client_id:     'test_client_id',
               client_secret: 'test_client_secret',
               client_tenant: 'common',
             })

      allow(ExternalCredential).to receive(:request_account_to_link).and_return(
        request_token: state_token,
        authorize_url: 'https://login.microsoftonline.com/dummy',
      )

      allow(ExternalCredential::MicrosoftGraph).to receive_messages(
        authorize_tokens: token_response,
        user_info:        { preferred_username: 'user@example.com' },
      )

      # Populate session via link_account so the real Rails session store is used
      get '/api/v1/external_credentials/microsoft_graph/link_account', params: {
        notification:   'true',
        shared_mailbox: shared_mailbox,
      }
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
      it 'returns unprocessable content' do
        get '/api/v1/external_credentials/microsoft_graph/callback', params: { code: 'auth_code', state: 'wrong_state' }

        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end
end
