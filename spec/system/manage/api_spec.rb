# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Manage > API', type: :system do
  let(:agent)    { create(:agent) }
  let(:token)    { create(:token, user: admin, preferences: { permission: %w[ticket.agent] }) }
  let(:admin)    { User.find_by(login: 'admin@example.com') }
  let(:mcp_path) { "#{Setting.get('http_type')}://#{Setting.get('fqdn')}/mcp" }

  # The request goes to the spec's own server, over its self-signed certificate.
  def mcp_initialize
    uri  = URI("https://127.0.0.1:#{Capybara.current_session.server.port}/mcp")
    http = Net::HTTP.new(uri.host, uri.port)

    http.use_ssl     = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE

    http.post(
      uri.path,
      { jsonrpc: '2.0', id: 1, method: 'initialize', params: { protocolVersion: '2025-11-25', capabilities: {}, clientInfo: { name: 'spec', version: '1.0' } } }.to_json,
      { 'Content-Type' => 'application/json', 'Accept' => 'application/json, text/event-stream', 'Authorization' => "Bearer #{token.token}" }
    )
  end

  before { visit 'system/api' }

  context 'when logged in as an admin' do
    it 'shows the MCP server switched off, with its address and an example' do
      within :active_content do
        expect(page).to have_field('api_mcp_access', type: :checkbox, visible: :all, checked: false)
        expect(page).to have_css('h2', text: 'MCP server')
        expect(page).to have_text("URL: #{mcp_path}")
        expect(page).to have_text("claude mcp add --transport http zammad #{mcp_path} --header \"Authorization: Bearer …\"")
        expect(page).to have_text('The MCP server works only while token access is enabled.')
      end
    end

    it 'builds the address and the example from the address settings' do
      Setting.set('http_type', 'http')
      Setting.set('fqdn', 'support.example.com')

      refresh

      within :active_content do
        expect(page).to have_text('URL: http://support.example.com/mcp')
        expect(page).to have_text('claude mcp add --transport http zammad http://support.example.com/mcp')
      end
    end

    it 'sets the title of the page' do
      expect(page).to have_title('API')
    end

    it 'gives the switch the name of its heading' do
      within :active_content do
        heading = find('h2', text: 'MCP server')

        expect(find('#api_mcp_access', visible: :all)['aria-labelledby']).to eq(heading[:id])
      end
    end

    it 'switches the MCP server on and off, and the server follows', :aggregate_failures do
      expect(mcp_initialize.code).to eq('403')

      within :active_content do
        find('.js-McpAccess label').click
      end

      wait_for_setting('api_mcp_access', true)
      expect(mcp_initialize.code).to eq('200')

      visit 'system/api'

      within :active_content do
        expect(page).to have_field('api_mcp_access', type: :checkbox, visible: :all, checked: true)
        find('.js-McpAccess label').click
      end

      wait_for_setting('api_mcp_access', false)
      expect(mcp_initialize.code).to eq('403')
    end

    it 'keeps token access and password access working beside it' do
      within :active_content do
        expect(page).to have_field('api_token_access', type: :checkbox, visible: :all, checked: true)
        expect(page).to have_field('api_password_access', type: :checkbox, visible: :all)
      end
    end

    it 'keeps the OAuth applications working in a tab of their own', :aggregate_failures do
      within :active_content do
        click_on 'OAuth'

        expect(page).to have_text('Applications (OAuth Authentication)')
        expect(page).to have_no_css('.js-McpAccess')

        click_on 'New Application'
      end

      in_modal do
        expect(page).to have_field('name')
      end
    end
  end

  context 'when logged in as an agent', authenticated_as: :agent do
    it 'sends the agent away from the page' do
      expect(page).to have_no_css('.js-McpAccess')
      expect(page).to have_current_path(%r{/#profile}, url: true)
    end
  end
end
