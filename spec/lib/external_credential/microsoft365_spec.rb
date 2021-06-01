# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe ExternalCredential::Microsoft365 do

  let(:token_url) { 'https://login.microsoftonline.com/common/oauth2/v2.0/token' }
  let(:token_url_with_tenant) { 'https://login.microsoftonline.com/tenant/oauth2/v2.0/token' }
  let(:authorize_url) { "https://login.microsoftonline.com/common/oauth2/v2.0/authorize?access_type=offline&client_id=#{client_id}&prompt=consent&redirect_uri=http%3A%2F%2Fzammad.example.com%2Fapi%2Fv1%2Fexternal_credentials%2Fmicrosoft365%2Fcallback&response_type=code&scope=https%3A%2F%2Foutlook.office.com%2FIMAP.AccessAsUser.All+https%3A%2F%2Foutlook.office.com%2FSMTP.Send+offline_access+openid+profile+email" }
  let(:authorize_url_with_tenant) { "https://login.microsoftonline.com/tenant/oauth2/v2.0/authorize?access_type=offline&client_id=#{client_id}&prompt=consent&redirect_uri=http%3A%2F%2Fzammad.example.com%2Fapi%2Fv1%2Fexternal_credentials%2Fmicrosoft365%2Fcallback&response_type=code&scope=https%3A%2F%2Foutlook.office.com%2FIMAP.AccessAsUser.All+https%3A%2F%2Foutlook.office.com%2FSMTP.Send+offline_access+openid+profile+email" }

  let(:id_token) { 'eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsImtpZCI6ImtnMkxZczJUMENUaklmajRydDZKSXluZW4zOCJ9.eyJhdWQiOiIyMTk4NTFhYS0wMDAwLTRhNDctMTExMS0zMmQwNzAyZTAxMjM0IiwiaXNzIjoiaHR0cHM6Ly9sb2dpbi5taWNyb3NvZnRvbmxpbmUuY29tLzM2YTlhYjU1LWZpZmEtMjAyMC04YTc4LTkwcnM0NTRkYmNmZDJkL3YyLjAiLCJpYXQiOjEzMDE1NTE4MzUsIm5iZiI6MTMwMTU1MTgzNSwiZXhwIjoxNjAxNTU5NzQ0LCJuYW1lIjoiRXhhbXBsZSBVc2VyIiwib2lkIjoiMTExYWIyMTQtMTJzNy00M2NnLThiMTItM2ozM2UydDBjYXUyIiwicHJlZmVycmVkX3VzZXJuYW1lIjoidGVzdEBleGFtcGxlLmNvbSIsImVtYWlsIjoidGVzdEBleGFtcGxlLmNvbSIsInJoIjoiMC40MjM0LWZmZnNmZGdkaGRLZUpEU1hiejlMYXBSbUNHZGdmZ2RmZ0kwZHkwSEF1QlhaSEFNYy4iLCJzdWIiOiJYY0VlcmVyQkVnX0EzNWJlc2ZkczNMTElXNjU1NFQtUy0ycGRnZ2R1Z3c1NDNXT2xJIiwidGlkIjoiMzZhOWFiNTUtZmlmYS0yMDIwLThhNzgtOTByczQ1NGRiY2ZkMmQiLCJ1dGkiOiJEU0dGZ3Nhc2RkZmdqdGpyMzV3cWVlIiwidmVyIjoiMi4wIn0=.l0nglq4rIlkR29DFK3PQFQTjE-VeHdgLmcnXwGvT8Z-QBaQjeTAcoMrVpr0WdL6SRYiyn2YuqPnxey6N0IQdlmvTMBv0X_dng_y4CiQ8ABdZrQK0VSRWZViboJgW5iBvJYFcMmVoilHChueCzTBnS1Wp2KhirS2ymUkPHS6AB98K0tzOEYciR2eJsJ2JOdo-82oOW4w6tbbqMvzT3DzsxqPQRGe2hUbNqo6gcwJLqq4t0bNf5XiYThw1sv4IivERmqW_pfybXEseKyZGd4NnJ6WwwOgTz5tkoLwls_YeDZVcp_Fpw9XR7J0UlyPqLtoUEjVihdyrJjAbdtHFKdOjrw' }
  let(:access_token) { '000.0000lvC3gAbjs8CYoKitfqM5LBS5N13374MCg6pNpZ28mxO2HuZvg0000_rsW00aACmFEto1BJeGDuu0000vmV6Esqv78iec-FbEe842ZevQtOOemQyQXjhMs62K1E6g3ehDLPRp6j4vtpSKSb6I-3MuDPfdzdqI23hM0' }
  let(:refresh_token) { '1//00000VO1ES0hFCgYIARAAGAkSNwF-L9IraWQNMj5ZTqhB00006DssAYcpEyFks5OuvZ1337wrqX0D7tE5o71FIPzcWEMM5000004' }
  let(:request_token) { nil } # not used but required by ExternalCredential API

  let(:scope_payload) { 'https://outlook.office.com/IMAP.AccessAsUser.All https://outlook.office.com/SMTP.Send offline_access openid profile email' }
  let(:scope_stub) { scope_payload }

  let(:client_id) { '123' }
  let(:client_secret) { '345' }
  let(:client_tenant) { 'tenant' }
  let(:authorization_code) { '567' }

  let(:email_address) { 'test@example.com' }
  let(:provider) { 'microsoft365' }
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

    context 'success' do

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

        create(:external_credential, name: provider, credentials: { client_id: client_id, client_secret: client_secret } )
      end

      it 'creates a Channel instance' do

        channel = described_class.link_account(request_token, authorization_payload)

        expect(channel.options).to match(
          a_hash_including(
            'inbound'  => a_hash_including(
              'options' => a_hash_including(
                'auth_type' => 'XOAUTH2',
                'host'      => 'outlook.office365.com',
                'ssl'       => true,
                'user'      => email_address,
              )
            ),
            'outbound' => a_hash_including(
              'options' => a_hash_including(
                'authentication' => 'xoauth2',
                'host'           => 'smtp.office365.com',
                'domain'         => 'office365.com',
                'port'           => 587,
                'user'           => email_address,
              )
            ),
            'auth'     => a_hash_including(
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
        )
      end
    end

    context 'API errors' do

      before do
        stub_request(:post, token_url).to_return(status: response_status, body: response_payload&.to_json, headers: {})

        create(:external_credential, name: provider, credentials: { client_id: client_id, client_secret: client_secret } )
      end

      shared_examples 'failed attempt' do
        it 'raises an exception' do
          expect do
            described_class.link_account(request_token, authorization_payload)
          end.to raise_error(RuntimeError, exception_message)
        end
      end

      context '404 invalid_client' do
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

      context '500 Internal Server Error' do
        let(:response_status) { 500 }
        let(:response_payload) { nil }
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

      create(:external_credential, name: provider, credentials: { client_id: client_id, client_secret: client_secret } )
      channel = described_class.link_account(request_token, authorization_payload)

      # remove stubs and allow new stubbing for tested requests
      WebMock.reset!

      channel
    end

    before do
      # we check the TTL of tokens and therefore need freeze the time
      freeze_time
    end

    context 'success' do

      let!(:expired_at) { channel.options['auth']['created_at'] }

      before do
        stub_request(:post, token_url).to_return(status: 200, body: response_payload.to_json, headers: {})
      end

      context 'access_token still valid' do
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

      context 'access_token expired' do
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
          end.to change { channel.options['auth'] }.to a_hash_including(
            'created_at'   => Time.zone.now,
            'access_token' => refreshed_access_token,
          )
        end
      end
    end

    context 'API errors' do

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

      context '400 invalid_client' do
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

      context '500 Internal Server Error' do
        let(:response_status) { 500 }
        let(:response_payload) { nil }
        let(:exception_message) { %r{code: 500} }

        include_examples 'failed attempt'
      end
    end
  end

  describe '.request_account_to_link' do
    it 'generates authorize_url from credentials' do
      microsoft365 = create(:external_credential, name: provider, credentials: { client_id: client_id, client_secret: client_secret } )
      request      = described_class.request_account_to_link(microsoft365.credentials)

      expect(request[:authorize_url]).to eq(authorize_url)
    end

    context 'errors' do

      shared_examples 'failed attempt' do
        it 'raises an exception' do
          expect do
            described_class.request_account_to_link(credentials, app_required)
          end.to raise_error(Exceptions::UnprocessableEntity, exception_message)
        end
      end

      context 'missing credentials' do
        let(:credentials) { nil }
        let(:app_required) { true }
        let(:exception_message) { 'No Microsoft365 app configured!' }

        include_examples 'failed attempt'
      end

      context 'missing client_id' do
        let(:credentials) do
          {
            client_secret: client_secret
          }
        end
        let(:app_required) { false }
        let(:exception_message) { 'No client_id param!' }

        include_examples 'failed attempt'
      end

      context 'missing client_secret' do
        let(:credentials) do
          {
            client_id: client_id
          }
        end
        let(:app_required) { false }
        let(:exception_message) { 'No client_secret param!' }

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
end
