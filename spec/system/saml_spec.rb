# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'SAML TESTING', integration: true, required_envs: %w[KEYCLOAK_BASE_URL KEYCLOAK_ADMIN KEYCLOAK_ADMIN_PASSWORD], type: :system do
  # Shared/persistent variables
  saml_initialized = false
  saml_access_token = ''

  let(:saml_base_url)               { ENV['KEYCLOAK_BASE_URL'] }
  let(:zammad_base_url)             { "#{Capybara.app_host}:#{Capybara.current_session.server.port}" }
  let(:saml_auth_endpoint)          { "#{saml_base_url}/realms/master/protocol/openid-connect/token" }
  let(:saml_auth_payload)           { { username: ENV['KEYCLOAK_ADMIN'], password: ENV['KEYCLOAK_ADMIN_PASSWORD'], grant_type: 'password', client_id: 'admin-cli' } }
  let(:saml_client_import_endpoint) { "#{saml_base_url}/admin/realms/zammad/clients" }
  let(:saml_auth_headers)           { { Authorization: "Bearer #{saml_access_token}" } }
  let(:saml_client_json)            { Rails.root.join('test/data/saml/zammad-client.json').read.gsub('ZAMMAD_BASE_URL', zammad_base_url) }

  # Only before(:each) can access let() variables.
  before do
    return if saml_initialized

    # Get auth token
    response = UserAgent.post(saml_auth_endpoint, saml_auth_payload)
    raise 'Authentication failed' if !response.success?

    saml_access_token = JSON.parse(response.body)['access_token']
    raise 'No access_token found' if saml_access_token.blank?

    # Import zammad client
    response = UserAgent.post(saml_client_import_endpoint, JSON.parse(saml_client_json), { headers: saml_auth_headers, json: true, jsonParseDisable: true })
    raise 'Authentication failed' if !response.success?

    saml_initialized = true
  end

  context 'with SAML authentication' do
    it 'works as expected ;)' do
      # TODO: real tests must follow later.
      expect(saml_initialized).to be(true)
    end
  end

end
