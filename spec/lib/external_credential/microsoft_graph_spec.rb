# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe ExternalCredential::MicrosoftGraph do

  let(:token_url)                 { 'https://login.microsoftonline.com/common/oauth2/v2.0/token' }
  let(:token_url_with_tenant)     { 'https://login.microsoftonline.com/tenant/oauth2/v2.0/token' }
  let(:authorize_url)             { "https://login.microsoftonline.com/common/oauth2/v2.0/authorize?access_type=offline&client_id=#{client_id}&prompt=login&redirect_uri=http%3A%2F%2Fzammad.example.com%2Fapi%2Fv1%2Fexternal_credentials%2Fmicrosoft_graph%2Fcallback&response_type=code&scope=offline_access+openid+profile+email+mail.readwrite+mail.readwrite.shared+mail.send+mail.send.shared" }
  let(:authorize_url_with_tenant) { "https://login.microsoftonline.com/tenant/oauth2/v2.0/authorize?access_type=offline&client_id=#{client_id}&prompt=login&redirect_uri=http%3A%2F%2Fzammad.example.com%2Fapi%2Fv1%2Fexternal_credentials%2Fmicrosoft_graph%2Fcallback&response_type=code&scope=offline_access+openid+profile+email+mail.readwrite+mail.readwrite.shared+mail.send+mail.send.shared" }

  let(:id_token) { 'eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsImtpZCI6ImtnMkxZczJUMENUaklmajRydDZKSXluZW4zOCJ9.eyJhdWQiOiIyMTk4NTFhYS0wMDAwLTRhNDctMTExMS0zMmQwNzAyZTAxMjM0IiwiaXNzIjoiaHR0cHM6Ly9sb2dpbi5taWNyb3NvZnRvbmxpbmUuY29tLzM2YTlhYjU1LWZpZmEtMjAyMC04YTc4LTkwcnM0NTRkYmNmZDJkL3YyLjAiLCJpYXQiOjEzMDE1NTE4MzUsIm5iZiI6MTMwMTU1MTgzNSwiZXhwIjoxNjAxNTU5NzQ0LCJuYW1lIjoiRXhhbXBsZSBVc2VyIiwib2lkIjoiMTExYWIyMTQtMTJzNy00M2NnLThiMTItM2ozM2UydDBjYXUyIiwicHJlZmVycmVkX3VzZXJuYW1lIjoidGVzdEBleGFtcGxlLmNvbSIsImVtYWlsIjoidGVzdEBleGFtcGxlLmNvbSIsInJoIjoiMC40MjM0LWZmZnNmZGdkaGRLZUpEU1hiejlMYXBSbUNHZGdmZ2RmZ0kwZHkwSEF1QlhaSEFNYy4iLCJzdWIiOiJYY0VlcmVyQkVnX0EzNWJlc2ZkczNMTElXNjU1NFQtUy0ycGRnZ2R1Z3c1NDNXT2xJIiwidGlkIjoiMzZhOWFiNTUtZmlmYS0yMDIwLThhNzgtOTByczQ1NGRiY2ZkMmQiLCJ1dGkiOiJEU0dGZ3Nhc2RkZmdqdGpyMzV3cWVlIiwidmVyIjoiMi4wIn0=.l0nglq4rIlkR29DFK3PQFQTjE-VeHdgLmcnXwGvT8Z-QBaQjeTAcoMrVpr0WdL6SRYiyn2YuqPnxey6N0IQdlmvTMBv0X_dng_y4CiQ8ABdZrQK0VSRWZViboJgW5iBvJYFcMmVoilHChueCzTBnS1Wp2KhirS2ymUkPHS6AB98K0tzOEYciR2eJsJ2JOdo-82oOW4w6tbbqMvzT3DzsxqPQRGe2hUbNqo6gcwJLqq4t0bNf5XiYThw1sv4IivERmqW_pfybXEseKyZGd4NnJ6WwwOgTz5tkoLwls_YeDZVcp_Fpw9XR7J0UlyPqLtoUEjVihdyrJjAbdtHFKdOjrw' }
  let(:access_token)  { '000.0000lvC3gAbjs8CYoKitfqM5LBS5N13374MCg6pNpZ28mxO2HuZvg0000_rsW00aACmFEto1BJeGDuu0000vmV6Esqv78iec-FbEe842ZevQtOOemQyQXjhMs62K1E6g3ehDLPRp6j4vtpSKSb6I-3MuDPfdzdqI23hM0' }
  let(:refresh_token) { '1//00000VO1ES0hFCgYIARAAGAkSNwF-L9IraWQNMj5ZTqhB00006DssAYcpEyFks5OuvZ1337wrqX0D7tE5o71FIPzcWEMM5000004' }
  let(:request_token) { nil } # not used but required by ExternalCredential API

  let(:scope_payload) { 'offline_access openid user.readbasic.all mail.readwrite mail.readwrite.shared mail.send mail.send.shared' }
  let(:scope_stub) { scope_payload }

  let(:client_id) { '123' }
  let(:client_secret)      { '345' }
  let(:client_tenant)      { 'tenant' }
  let(:authorization_code) { '567' }

  let(:email_address) { 'test@example.com' }
  let(:provider)  { 'microsoft_graph' }
  let(:token_ttl) { 3599 }

  let!(:token_response_payload) do
    {
      'access_token'  => access_token,
      'expires_in'    => token_ttl,
      'refresh_token' => refresh_token,
      'scope'         => scope_stub,
      'token_type'    => 'Bearer',
      'id_token'      => id_token,
      'type'          => 'XOAUTH2',
    }
  end

  describe '.link_account' do
    let!(:authorization_payload) do
      {
        code:       authorization_code,
        scope:      scope_payload,
        authuser:   '4',
        hd:         'example.com',
        prompt:     'consent',
        controller: 'external_credentials',
        action:     'callback',
        provider:   provider
      }
    end

    before do
      # we check the TTL of tokens and therefore need freeze the time
      freeze_time
    end

    context 'when success' do

      let(:request_payload) do
        {
          'client_secret' => client_secret,
          'code'          => authorization_code,
          'grant_type'    => 'authorization_code',
          'client_id'     => client_id,
          'redirect_uri'  => ExternalCredential.callback_url(provider),
        }
      end

      before do
        stub_request(:post, token_url)
          .with(body: hash_including(request_payload))
          .to_return(status: 200, body: token_response_payload.to_json, headers: {})

        create(:external_credential, name: provider, credentials: { client_id: client_id, client_secret: client_secret })
      end

      it 'creates a Channel instance', :aggregate_failures do
        channel = described_class.link_account(request_token, authorization_payload)

        expect(channel.options).to include(
          'inbound'  => {
            adapter: 'microsoft_graph_inbound',
            options: {
              'user' => email_address,
            }
          },
          'outbound' => {
            adapter: 'microsoft_graph_outbound',
            options: {
              'user' => email_address,
            }
          },
          'auth'     => include(
            'access_token'  => access_token,
            'expires_in'    => token_ttl,
            'refresh_token' => refresh_token,
            'scope'         => scope_stub,
            'token_type'    => 'Bearer',
            'id_token'      => id_token,
            'created_at'    => Time.zone.now,
            'type'          => 'XOAUTH2',
            'client_id'     => client_id,
            'client_secret' => client_secret,
          ),
        )

        channel.options[:inbound][:options][:keep_on_server] = true
        channel.save

        channel = described_class.link_account(request_token, authorization_payload.merge(channel_id: channel.id))
        expect(channel.reload.options[:inbound][:options][:keep_on_server]).to be(true)
      end

      context 'when users do not match', :aggregate_failures do
        let(:existing_channel) do
          # TODO: change ENV
          ENV['MICROSOFT365_USER']          = 'zammad@outlook.com'
          ENV['MICROSOFT365_CLIENT_ID']     = 'xxx'
          ENV['MICROSOFT365_CLIENT_SECRET'] = 'xxx'
          ENV['MICROSOFT365_CLIENT_TENANT'] = 'xxx'

          create(:microsoft_graph_channel)
        end

        it 'generates a link to an error dialog & does not update the channel' do
          link_account_response = described_class.link_account(request_token, authorization_payload.merge(channel_id: existing_channel.id))

          expect(link_account_response).to eq("#{Setting.get('http_type')}://#{Setting.get('fqdn')}/#channels/#{provider}/error/user_mismatch/channel/#{existing_channel.id}")

          expect(existing_channel.reload.options.dig(:inbound, :options, :user)).to eq('zammad@outlook.com')
          expect(existing_channel.reload.options.dig(:outbound, :options, :user)).to eq('zammad@outlook.com')
        end
      end
    end

    context 'when API errors' do
      before do
        stub_request(:post, token_url).to_return(status: response_status, body: response_payload&.to_json, headers: {})

        create(:external_credential, name: provider, credentials: { client_id: client_id, client_secret: client_secret })
      end

      shared_examples 'failed attempt' do
        it 'raises an exception' do
          expect do
            described_class.link_account(request_token, authorization_payload)
          end.to raise_error(RuntimeError, exception_message)
        end
      end

      context 'when 404 invalid_client' do
        let(:response_status) { 404 }
        let(:response_payload) do
          {
            error:             'invalid_client',
            error_description: 'The OAuth client was not found.'
          }
        end
        let(:exception_message) { 'Request failed! ERROR: invalid_client (The OAuth client was not found.)' }

        include_examples 'failed attempt'
      end

      context 'when 500 Internal Server Error' do
        let(:response_status) { 500 }
        let(:response_payload)  { nil }
        let(:exception_message) { 'Request failed! (code: 500)' }

        include_examples 'failed attempt'
      end
    end
  end

  describe '.refresh_token' do
    let!(:authorization_payload) do
      {
        code:       authorization_code,
        scope:      scope_payload,
        authuser:   '4',
        hd:         'example.com',
        prompt:     'consent',
        controller: 'external_credentials',
        action:     'callback',
        provider:   provider
      }
    end
    let!(:channel) do
      stub_request(:post, token_url).to_return(status: 200, body: token_response_payload.to_json, headers: {})

      create(:external_credential, name: provider, credentials: { client_id: client_id, client_secret: client_secret })
      channel = described_class.link_account(request_token, authorization_payload)

      # remove stubs and allow new stubbing for tested requests
      WebMock.reset!

      channel
    end

    before do
      # we check the TTL of tokens and therefore need freeze the time
      freeze_time
    end

    context 'when success' do
      before do
        stub_request(:post, token_url).to_return(status: 200, body: response_payload.to_json, headers: {})
      end

      context 'when access_token is still valid' do
        let(:response_payload) do
          {
            'access_token' => access_token,
            'expires_in'   => token_ttl,
            'scope'        => scope_stub,
            'token_type'   => 'Bearer',
            'type'         => 'XOAUTH2',
          }
        end

        it 'does not refresh' do
          expect do
            channel.refresh_xoauth2!
          end.not_to change { channel.options['auth']['created_at'] }
        end
      end

      context 'when access_token is expired' do
        let(:refreshed_access_token) { 'some_new_token' }

        let(:response_payload) do
          {
            'access_token' => refreshed_access_token,
            'expires_in'   => token_ttl,
            'scope'        => scope_stub,
            'token_type'   => 'Bearer',
            'type'         => 'XOAUTH2',
          }
        end

        before do
          travel 1.hour
        end

        it 'refreshes token' do
          expect do
            channel.refresh_xoauth2!
          end.to change { channel.options['auth'] }.to include(
            'created_at'   => Time.zone.now,
            'access_token' => refreshed_access_token,
          )
        end
      end
    end

    context 'when API errors' do

      before do
        stub_request(:post, token_url).to_return(status: response_status, body: response_payload&.to_json, headers: {})

        # invalidate existing token
        travel 1.hour
      end

      shared_examples 'failed attempt' do
        it 'raises an exception' do
          expect do
            channel.refresh_xoauth2!
          end.to raise_error(RuntimeError, exception_message)
        end
      end

      context 'when 400 invalid_client' do
        let(:response_status) { 400 }
        let(:response_payload) do
          {
            error:             'invalid_client',
            error_description: 'The OAuth client was not found.'
          }
        end
        let(:exception_message) { %r{The OAuth client was not found} }

        include_examples 'failed attempt'
      end

      context 'when 500 Internal Server Error' do
        let(:response_status)   { 500 }
        let(:response_payload)  { nil }
        let(:exception_message) { %r{code: 500} }

        include_examples 'failed attempt'
      end
    end
  end

  describe '.request_account_to_link' do
    it 'generates authorize_url from credentials' do
      microsoft_graph = create(:external_credential, name: provider, credentials: { client_id: client_id, client_secret: client_secret })
      request = described_class.request_account_to_link(microsoft_graph.credentials)

      expect(request[:authorize_url]).to eq(authorize_url)
    end

    context 'when errors' do

      shared_examples 'failed attempt' do
        it 'raises an exception' do
          expect do
            described_class.request_account_to_link(credentials, app_required)
          end.to raise_error(Exceptions::UnprocessableEntity, exception_message)
        end
      end

      context 'when missing credentials' do
        let(:credentials) { nil }
        let(:app_required)      { true }
        let(:exception_message) { 'No Microsoft Graph app configured!' }

        include_examples 'failed attempt'
      end

      context 'when missing client_id' do
        let(:credentials) do
          {
            client_secret: client_secret
          }
        end
        let(:app_required) { false }
        let(:exception_message) { "The required parameter 'client_id' is missing." }

        include_examples 'failed attempt'
      end

      context 'when missing client_secret' do
        let(:credentials) do
          {
            client_id: client_id
          }
        end
        let(:app_required) { false }
        let(:exception_message) { "The required parameter 'client_secret' is missing." }

        include_examples 'failed attempt'
      end
    end
  end

  describe '.generate_authorize_url' do
    it 'generates valid URL' do
      url = described_class.generate_authorize_url(client_id: client_id)
      expect(url).to eq(authorize_url)
    end

    it 'generates valid URL with tenant' do
      url = described_class.generate_authorize_url(client_id: client_id, client_tenant: 'tenant')
      expect(url).to eq(authorize_url_with_tenant)
    end
  end

  describe '.user_info' do
    it 'extracts user information from id_token' do
      info = described_class.user_info(id_token)
      expect(info[:email]).to eq(email_address)
    end
  end

  describe '.update_client_secret' do
    let(:channel) do
      # TODO: change ENV
      ENV['MICROSOFT365_USER'] = 'zammad@outlook.com'
      ENV['MICROSOFT365_CLIENT_ID']     = 'id1337'
      ENV['MICROSOFT365_CLIENT_SECRET'] = 'dummy'
      ENV['MICROSOFT365_CLIENT_TENANT'] = 'xxx'

      create(:microsoft_graph_channel)
    end

    let(:external_credential) { create(:external_credential, name: provider, credentials: { client_id: 'id1337', client_secret: 'dummy' }) }

    context 'when client_secret was updated' do
      context 'when secret is different' do
        before do
          channel.options[:auth][:client_secret] = 'dummy-other'
          channel.save!
        end

        it 'does not update the channel' do
          external_credential.update!(credentials: { client_id: 'id1337', client_secret: 'dummy-new' })

          expect(channel.reload.options[:auth][:client_secret]).to eq('dummy-other')
        end
      end

      context 'when secret is the same' do
        it 'updates the setting' do
          channel
          external_credential.update!(credentials: { client_id: 'id1337', client_secret: 'dummy-new' })

          expect(channel.reload.options[:auth][:client_secret]).to eq('dummy-new')
        end
      end
    end
  end
end
