# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe OmniAuth::Strategies::OidcDatabase do
  describe '#access_token' do
    subject(:strategy) { described_class.new(nil) }

    let(:identifier)     { 'zammad-client' }
    let(:token_endpoint) { 'https://idp.example.com/token' }
    let(:session)        { { 'omniauth.pkce.verifier' => 'pkce-verifier' } }

    before do
      Setting.set('auth_openid_connect_credentials', { 'identifier' => identifier, 'issuer' => 'https://idp.example.com', 'pkce' => pkce })

      stub_request(:post, token_endpoint).to_return(
        headers: { 'Content-Type' => 'application/json' },
        body:    { access_token: 'access-token', token_type: 'Bearer' }.to_json,
      )

      strategy.options.deep_merge!(described_class.setup)
      strategy.options.client_options.token_endpoint = token_endpoint
      strategy.send(:client).authorization_code = 'authorization-code'
      allow(strategy).to receive_messages(params: {}, session:)

      strategy.send(:access_token)
    end

    shared_examples 'authenticating as a public client' do
      it 'sends the client ID in the body without HTTP Basic credentials' do
        expect(
          a_request(:post, token_endpoint).with do |request|
            body = Rack::Utils.parse_query(request.body)

            request.headers.keys.none? { |key| key.casecmp?('Authorization') } &&
              body['client_id'] == identifier &&
              !body.key?('client_secret') &&
              body['code_verifier'] == expected_code_verifier
          end
        ).to have_been_made.once
      end
    end

    context 'with PKCE enabled' do
      let(:pkce)                   { true }
      let(:expected_code_verifier) { 'pkce-verifier' }

      it_behaves_like 'authenticating as a public client'
    end

    context 'with PKCE disabled' do
      let(:pkce)                   { false }
      let(:expected_code_verifier) { nil }

      it_behaves_like 'authenticating as a public client'
    end
  end
end
