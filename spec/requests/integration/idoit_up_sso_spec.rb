# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Integration::IdoitUpSso', type: :request do
  let(:agent)  { create(:agent, email: 'agent@example.com') }
  let(:secret) { 'shared-secret' }

  before do
    Setting.set('idoit_up_integration', true)
    Setting.set('idoit_up_config', { api_token: secret, endpoint: 'https://addon.example.com/' })
  end

  def sso_token(claims = {}, audience: 'zammad-sso', ttl: 60)
    IdoitUp::Token.sign({ sub: agent.email, jti: SecureRandom.uuid, redirect: '#ticket/zoom/7' }.merge(claims),
                        audience: audience, ttl: ttl, secret: secret)
  end

  describe 'GET /api/v1/integration/idoit_up/sso' do
    it 'starts a session for the user and opens the ticket', :aggregate_failures do
      get '/api/v1/integration/idoit_up/sso', params: { token: sso_token }

      expect(response).to redirect_to('/#ticket/zoom/7')
      get '/api/v1/users/me', params: { fingerprint: Faker::Number.unique.number(digits: 9) }, as: :json
      expect(response.parsed_body['email']).to eq(agent.email)
    end

    it 'rejects a replayed token' do
      token = sso_token
      get '/api/v1/integration/idoit_up/sso', params: { token: token }
      reset!
      get '/api/v1/integration/idoit_up/sso', params: { token: token }

      expect(response).to redirect_to('/#login')
    end

    it 'rejects tokens signed with another secret, for another audience or expired' do
      [
        IdoitUp::Token.sign({ sub: agent.email, jti: '1' }, audience: 'zammad-sso', secret: 'other'),
        sso_token({}, audience: 'idoit-addon'),
        sso_token({}, ttl: -60),
      ].each do |token|
        get '/api/v1/integration/idoit_up/sso', params: { token: token }
        expect(response).to redirect_to('/#login')
      end
    end

    it 'never redirects outside a ticket view' do
      get '/api/v1/integration/idoit_up/sso', params: { token: sso_token({ redirect: '//evil.example.com' }) }

      expect(response).to redirect_to('/#')
    end

    it 'rejects unknown users' do
      get '/api/v1/integration/idoit_up/sso', params: { token: sso_token({ sub: 'nobody@example.com' }) }

      expect(response).to redirect_to('/#login')
    end
  end

  describe 'GET /api/v1/integration/idoit_up/identify' do
    let(:nonce) { SecureRandom.hex(16) }

    it 'sends the logged-in user back to the add-on with a signed identity', :aggregate_failures do
      authenticated_as(agent, via: :browser)
      get '/api/v1/integration/idoit_up/identify', params: { nonce: nonce }

      location = URI.parse(response.location)
      expect("#{location.scheme}://#{location.host}#{location.path}").to eq('https://addon.example.com/oauth/callback')
      claims = IdoitUp::Token.verify(Rack::Utils.parse_query(location.query)['token'],
                                     audience: 'idoit-addon-oauth', secret: secret)
      expect(claims).to include('sub' => agent.email, 'nonce' => nonce)
    end

    it 'redirects to the login page without a session' do
      get '/api/v1/integration/idoit_up/identify', params: { nonce: nonce }

      expect(response).to redirect_to('/#login')
    end

    it 'ignores API token authentication' do
      token = create(:token, user: agent, preferences: { permission: ['ticket.agent'] })
      get '/api/v1/integration/idoit_up/identify', params:  { nonce: nonce },
                                                   headers: { 'Authorization' => "Token token=#{token.token}" }

      expect(response).to redirect_to('/#login')
    end

    it 'rejects a malformed nonce' do
      authenticated_as(agent, via: :browser)
      get '/api/v1/integration/idoit_up/identify', params: { nonce: 'x' }

      expect(response).to have_http_status(:unprocessable_content)
    end
  end
end
