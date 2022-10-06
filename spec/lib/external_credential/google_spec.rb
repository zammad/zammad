# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe ExternalCredential::Google do

  let(:token_url)     { 'https://accounts.google.com/o/oauth2/token' }
  let(:alias_url)     { 'https://www.googleapis.com/gmail/v1/users/me/settings/sendAs' }
  let(:authorize_url) { "https://accounts.google.com/o/oauth2/auth?access_type=offline&client_id=#{client_id}&prompt=consent&redirect_uri=http%3A%2F%2Fzammad.example.com%2Fapi%2Fv1%2Fexternal_credentials%2Fgoogle%2Fcallback&response_type=code&scope=openid+email+profile+https%3A%2F%2Fmail.google.com%2F" }

  let(:id_token) { 'eyJhbGciOiJSUzI1NiIsImtpZCI6Inh4eHh4eDkwYmNkNzZhZWIyMDAyNmY2Yjc3MGNhYzIyMTc4MyIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJhY2NvdW50cy5nb29nbGUuY29tIiwiYXpwIjoiMTMzNy1jdGYuYXBwcy5nb29nbGV1c2VyY29udGVudC5jb20iLCJhdWQiOiIxMzM3LWN0Zi5hcHBzLmdvb2dsZXVzZXJjb250ZW50LmNvbSIsInN1YiI6IjAwMDg5MjkxMzM3NDkxMDAwMDAyIiwiaGQiOiJleGFtcGxlLmNvbSIsImVtYWlsIjoidGVzdEBleGFtcGxlLmNvbSIsImVtYWlsX3ZlcmlmaWVkIjp0cnVlLCJhdF9oYXNoIjoibjAwd19fNVdwQ1RGNUcwMDBjbU56QSIsImlhdCI6MTU4NzczMjg5MywiZXhwIjoxNTg3NzM2NDkzfQ==' }
  let(:access_token)  { '000.0000lvC3gAbjs8CYoKitfqM5LBS5N13374MCg6pNpZ28mxO2HuZvg0000_rsW00aACmFEto1BJeGDuu0000vmV6Esqv78iec-FbEe842ZevQtOOemQyQXjhMs62K1E6g3ehDLPRp6j4vtpSKSb6I-3MuDPfdzdqI23hM0' }
  let(:refresh_token) { '1//00000VO1ES0hFCgYIARAAGAkSNwF-L9IraWQNMj5ZTqhB00006DssAYcpEyFks5OuvZ1337wrqX0D7tE5o71FIPzcWEMM5000004' }
  let(:request_token) { nil } # not used but required by ExternalCredential API

  let(:scope_payload) { 'email profile openid https://www.googleapis.com/auth/userinfo.email https://www.googleapis.com/auth/userinfo.profile https://mail.google.com/' }
  let(:scope_stub) { 'https://mail.google.com/ https://www.googleapis.com/auth/userinfo.email https://www.googleapis.com/auth/userinfo.profile openid' }

  let(:client_id) { '123' }
  let(:client_secret)      { '345' }
  let(:authorization_code) { '567' }

  let(:primary_email) { 'test@example.com' }
  let(:provider)  { 'google' }
  let(:token_ttl) { 3599 }

  let!(:alias_response_payload) do
    {
      'sendAs' => [
        {
          'sendAsEmail'    => primary_email,
          'displayName'    => '',
          'replyToAddress' => '',
          'signature'      => '',
          'isPrimary'      => true,
          'isDefault'      => true
        },
        {
          'sendAsEmail'        => 'alias1@example.com',
          'displayName'        => 'alias1',
          'replyToAddress'     => '',
          'signature'          => '',
          'verificationStatus' => 'accepted',
        },
        {
          'sendAsEmail'        => 'alias2@example.com',
          'displayName'        => 'alias2',
          'replyToAddress'     => '',
          'signature'          => '',
          'verificationStatus' => 'accepted',
        },
        {
          'sendAsEmail'        => 'alias3@example.com',
          'displayName'        => 'alias3',
          'replyToAddress'     => '',
          'signature'          => '',
          'verificationStatus' => 'accepted',
        },
      ]
    }
  end
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
        stub_request(:get, alias_url).to_return(status: 200, body: alias_response_payload.to_json, headers: {})

        create(:external_credential, name: provider, credentials: { client_id: client_id, client_secret: client_secret })
      end

      it 'creates a Channel instance' do

        channel = described_class.link_account(request_token, authorization_payload)

        expect(channel.options).to include(
          'inbound'  => include(
            'options' => include(
              'auth_type' => 'XOAUTH2',
              'host'      => 'imap.gmail.com',
              'ssl'       => 'ssl',
              'user'      => primary_email,
            )
          ),
          'outbound' => include(
            'options' => include(
              'authentication' => 'xoauth2',
              'host'           => 'smtp.gmail.com',
              'port'           => 465,
              'ssl'            => true,
              'user'           => primary_email,
            )
          ),
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
      end
    end

    context 'API errors' do

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
      stub_request(:get, alias_url).to_return(status: 200, body: alias_response_payload.to_json, headers: {})

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
          end.to change { channel.options['auth'] }.to include(
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
        let(:response_payload)  { nil }
        let(:exception_message) { %r{code: 500} }

        include_examples 'failed attempt'
      end
    end
  end

  describe '.request_account_to_link' do
    it 'generates authorize_url from credentials' do
      google  = create(:external_credential, name: provider, credentials: { client_id: client_id, client_secret: client_secret })
      request = described_class.request_account_to_link(google.credentials)

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
        let(:app_required)      { true }
        let(:exception_message) { 'There is no Google app configured.' }

        include_examples 'failed attempt'
      end

      context 'missing client_id' do
        let(:credentials) do
          {
            client_secret: client_secret
          }
        end
        let(:app_required) { false }
        let(:exception_message) { "The required parameter 'client_id' is missing." }

        include_examples 'failed attempt'
      end

      context 'missing client_secret' do
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

  describe '.user_aliases' do

    let(:response_status) { 200 }
    let(:response_payload) { alias_response_payload }

    let(:token) do
      {
        access_token: access_token,
        token_type:   'Bearer'
      }
    end

    before do
      stub_request(:get, alias_url).to_return(status: response_status, body: response_payload&.to_json, headers: {})
    end

    it 'returns the google user email aliases' do
      result = described_class.user_aliases(token)
      expect(result).to eq([
                             { realname: 'alias1', email: 'alias1@example.com' },
                             { realname: 'alias2', email: 'alias2@example.com' },
                             { realname: 'alias3', email: 'alias3@example.com' }
                           ])
    end

    context 'API errors' do

      context '401 Unauthorized' do
        let(:response_status) { 401 }
        let(:response_payload) do
          {
            error: {
              code:    401,
              message: 'Invalid Credentials',
              errors:  [
                {
                  locationType: 'header',
                  domain:       'global',
                  message:      'Invalid Credentials',
                  reason:       'authError',
                  location:     'Authorization'
                }
              ]
            }
          }
        end

        it 'raises an exception' do
          expect do
            described_class.user_aliases(token)
          end.to raise_error(RuntimeError, 'Request failed! ERROR: Invalid Credentials')
        end
      end

      context '500 Internal Server Error' do
        let(:response_status)  { 500 }
        let(:response_payload) { nil }

        it 'raises an exception' do
          expect do
            described_class.user_aliases(token)
          end.to raise_error(RuntimeError, 'Request failed! (code: 500)')
        end
      end
    end
  end

  describe '.generate_authorize_url' do
    it 'generates valid URL' do
      url = described_class.generate_authorize_url(client_id)
      expect(url).to eq(authorize_url)
    end
  end

  describe '.user_info' do
    it 'extracts user information from id_token' do
      info = described_class.user_info(id_token)
      expect(info[:email]).to eq(primary_email)
    end
  end
end
