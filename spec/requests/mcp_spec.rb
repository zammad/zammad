# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'json_schemer'

# Pins the MCP specification from outside, in both revisions the server speaks, so that an update of the gem cannot
# change it unnoticed. Answers are checked against the official JSON schemas (spec/fixtures/files/mcp/schema).
RSpec.describe 'MCP server', :aggregate_failures, type: :request do
  let(:agent)     { create(:agent) }
  let(:token)     { create(:token, user: agent, preferences: { permission: %w[ticket.agent] }) }
  let(:tool_runs) { [] }

  let(:schemas) do
    %w[2025-11-25 2026-07-28].index_with do |revision|
      JSON.parse(Rails.root.join("spec/fixtures/files/mcp/schema/#{revision}.json").read)
    end
  end

  before do
    Setting.set('api_mcp_access', true)
    host! 'localhost'

    runs = tool_runs

    stub_const('Service::AI::Tool::EchoText', Class.new(Service::AI::Tool) do
      description 'Echoes the text back.'
      title       'Echo text'
      effect      :read
      permission  'ticket.agent'
      offered_in  :mcp
      audiences   :human_agents
      output_schema type: 'object', properties: { text: { type: 'string' } }, required: %w[text]

      parameter :text, type: :string, description: 'The text to echo.', required: true

      define_method(:execute) do
        runs << argument(:text)

        Service::AI::Tool::Runtime::Result.ok({ text: argument(:text) }, text: argument(:text))
      end
    end)
  end

  def mcp_post(body, headers: {}, token: self.token, raw: nil, path: '/mcp')
    all_headers = { 'Content-Type' => 'application/json', 'Accept' => 'application/json, text/event-stream' }
    all_headers['Authorization'] = "Bearer #{token.token}" if token

    post path, params: raw || body.to_json, headers: all_headers.merge(headers)
  end

  # 2025-11-25: after the handshake, every request names the negotiated version in a header.
  def legacy_request(method, params = nil, id: 1, headers: {}, **)
    mcp_post({ jsonrpc: '2.0', id:, method:, params: }.compact, headers: { 'MCP-Protocol-Version' => '2025-11-25' }.merge(headers), **)
  end

  # 2026-07-28: no handshake; every request carries the version and the client's capabilities.
  def modern_request(method, params = {}, id: 1, name: nil, headers: {}, capabilities: {}, **)
    meta    = { 'io.modelcontextprotocol/protocolVersion' => '2026-07-28', 'io.modelcontextprotocol/clientCapabilities' => capabilities }
    mirrors = { 'MCP-Protocol-Version' => '2026-07-28', 'Mcp-Method' => method, 'Mcp-Name' => name }.compact

    mcp_post({ jsonrpc: '2.0', id:, method:, params: params.merge(_meta: meta) }, headers: mirrors.merge(headers), **)
  end

  def initialize_request(version: '2025-11-25', **)
    mcp_post({ jsonrpc: '2.0', id: 1, method: 'initialize', params: { protocolVersion: version, capabilities: {}, clientInfo: { name: 'spec', version: '1.0' } } }, **)
  end

  def expect_valid(revision, definition, value)
    errors = JSONSchemer.schema(schemas[revision].merge('$ref' => "#/$defs/#{definition}")).validate(value).map { |error| error['error'] }

    expect(errors).to be_empty, "#{definition} (#{revision}): #{errors.first(3).join(' | ')}"
  end

  # The structured content of a call against the output schema its tool was listed with, as clients check it.
  def expect_valid_output(tool_list, call_result)
    tool   = tool_list['tools'].find { |listed| listed['name'] == 'echo_text' }
    errors = output_schema_errors(tool['outputSchema'], call_result['structuredContent'])

    expect(JSONSchemer.schema(tool['outputSchema']).valid_schema?).to be(true)
    expect(errors).to be_empty, errors.first(3).join(' | ')
  end

  # Zammad's own refusals carry no id, which the schema allows and the transport asks for an answer to no request.
  def expect_refusal(status, message)
    expect_error_without_id(status)
    expect(json_response['error']).to eq('code' => -32_600, 'message' => message)
  end

  def expect_error_without_id(status)
    expect(response).to have_http_status(status)
    expect(json_response.keys).to eq(%w[jsonrpc error])
    expect_valid('2025-11-25', 'JSONRPCErrorResponse', json_response)
    expect_valid('2026-07-28', 'JSONRPCErrorResponse', json_response)
  end

  describe 'refusals, in the order the specification asks for' do
    it 'refuses a foreign origin with 403 before it looks at the token' do
      legacy_request('tools/list', headers: { 'Origin' => 'https://attacker.example' }, token: nil)
      expect_refusal(:forbidden, 'This address is not allowed.')

      legacy_request('tools/list', headers: { 'Origin' => 'null' })
      expect_refusal(:forbidden, 'This address is not allowed.')
    end

    it 'refuses a host that is not Zammad\'s with 403' do
      host! 'attacker.example'
      legacy_request('tools/list')

      expect_refusal(:forbidden, 'This address is not allowed.')
    end

    it 'answers a request without a personal access token with 401 and a bearer challenge without an error' do
      password = 'some-Password-123'
      user     = create(:agent, password:)

      legacy_request('tools/list', token: nil)
      expect_refusal(:unauthorized, 'A personal access token is required.')
      expect(response.headers['WWW-Authenticate']).to eq('Bearer realm="Zammad"')

      legacy_request('tools/list', token: nil, headers: { 'Authorization' => ActionController::HttpAuthentication::Basic.encode_credentials(user.login, password) })
      expect_refusal(:unauthorized, 'A personal access token is required.')

      post '/api/v1/signin', params: { username: user.login, password:, fingerprint: '123456789' }, as: :json
      legacy_request('tools/list', token: nil)
      expect_refusal(:unauthorized, 'A personal access token is required.')
    end

    it 'answers an invalid token with 401 and error="invalid_token"' do
      expired       = create(:token, user: agent, expires_at: 1.day.ago, preferences: { permission: %w[ticket.agent] })
      inactive_user = create(:agent, active: false)
      inactive      = create(:token, user: inactive_user, preferences: { permission: %w[ticket.agent] })
      oauth_app     = Doorkeeper::Application.create!(name: 'Spec', redirect_uri: 'https://localhost', scopes: '')
      oauth         = Doorkeeper::AccessToken.create!(application: oauth_app, resource_owner_id: agent.id, scopes: '')

      [expired.token, inactive.token, oauth.token, 'not-a-token'].each do |token_string|
        legacy_request('tools/list', token: nil, headers: { 'Authorization' => "Bearer #{token_string}" })

        expect(response).to have_http_status(:unauthorized)
        expect(response.headers['WWW-Authenticate']).to eq('Bearer realm="Zammad", error="invalid_token"')
      end
    end

    it 'refuses acting on behalf of another user with 403, also for a user allowed to do so elsewhere' do
      admin_token = create(:token, user: create(:admin), preferences: { permission: %w[ticket.agent admin.session] })

      legacy_request('tools/list', token: admin_token, headers: { 'From' => agent.email })
      expect_refusal(:forbidden, 'Acting on behalf of another user is not supported.')

      legacy_request('tools/list', token: admin_token, headers: { 'X-On-Behalf-Of' => agent.email })
      expect_refusal(:forbidden, 'Acting on behalf of another user is not supported.')
    end

    it 'refuses every request while the MCP server is switched off' do
      Setting.set('api_mcp_access', false)
      legacy_request('tools/list')
      expect_refusal(:forbidden, 'The MCP server is switched off.')

      legacy_request('tools/list', token: nil)
      expect_refusal(:forbidden, 'The MCP server is switched off.')

      legacy_request('tools/list', token: nil, headers: { 'Authorization' => 'Bearer not-a-token' })
      expect_refusal(:forbidden, 'The MCP server is switched off.')
    end

    it 'refuses every request while token access to the API is switched off' do
      Setting.set('api_token_access', false)
      legacy_request('tools/list')

      expect(response).to have_http_status(:forbidden)
    end

    it 'refuses a user without admin rights in maintenance mode' do
      Setting.set('maintenance_mode', true)
      legacy_request('tools/list')

      expect(response).to have_http_status(:forbidden)
    end

    it 'refuses a body larger than the transport accepts with 413, after the token, and runs nothing' do
      stub_const('Rack::Middleware::MCPBodyLimit::LIMIT', 200)

      legacy_request('tools/call', { name: 'echo_text', arguments: { text: 'x' * 300 } }, token: nil)
      expect(response).to have_http_status(:unauthorized)

      legacy_request('tools/call', { name: 'echo_text', arguments: { text: 'x' * 300 } })
      expect_refusal(:content_too_large, 'The request body is too large.')
      expect(tool_runs).to be_empty
    end

    it 'serves /mcp only, without a format' do
      legacy_request('tools/list', path: '/mcp.json')

      expect(response).to have_http_status(:not_found)
    end

    it 'answers a failure with a JSON-RPC error that names no internals' do
      allow(Service::MCPServer::HandleRequest).to receive(:execute).and_raise(ActiveRecord::StatementInvalid, 'PG::Error: secret details')

      legacy_request('tools/list')

      expect(response).to have_http_status(:internal_server_error)
      expect(json_response).to eq('jsonrpc' => '2.0', 'error' => { 'code' => -32_603, 'message' => 'Internal error' })
    end

    it 'answers GET and DELETE with 405 and Allow: POST' do
      get '/mcp'
      expect(response).to have_http_status(:method_not_allowed)
      expect(response.headers['Allow']).to eq('POST')

      delete '/mcp'
      expect(response).to have_http_status(:method_not_allowed)
      expect(response.headers['Allow']).to eq('POST')
    end
  end

  describe 'revision 2025-11-25, with the handshake' do
    it 'negotiates the version and announces the tools only, without a session' do
      initialize_request

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq('application/json')
      expect(response.headers['Mcp-Session-Id']).to be_nil
      expect(json_response['result']).to include(
        'protocolVersion' => '2025-11-25',
        'capabilities'    => { 'tools' => {} },
        'serverInfo'      => include('name' => 'zammad', 'title' => 'Zammad', 'version' => Version.get),
      )
      expect_valid('2025-11-25', 'InitializeResult', json_response['result'])
    end

    it 'answers a version it does not speak, or the stateless one, with 2025-11-25' do
      %w[1999-01-01 2026-07-28].each do |version|
        initialize_request(version:)

        expect(json_response.dig('result', 'protocolVersion')).to eq('2025-11-25')
      end
    end

    it 'accepts a notification with 202 and no body' do
      mcp_post({ jsonrpc: '2.0', method: 'notifications/initialized' }, headers: { 'MCP-Protocol-Version' => '2025-11-25' })

      expect(response).to have_http_status(:accepted)
      expect(response.body).to be_empty
    end

    it 'answers ping' do
      legacy_request('ping')

      expect(json_response['result']).to eq({})
      expect_valid('2025-11-25', 'EmptyResult', json_response['result'])
    end

    it 'lists the tools and runs one' do
      legacy_request('tools/list')
      tool_list = json_response['result']
      expect(tool_list['tools'].pluck('name', 'title')).to eq(
        [
          ['add_internal_note', 'Add internal note'], ['create_article', 'Create article'], ['create_ticket', 'Create ticket'], ['echo_text', 'Echo text'], ['get_current_user', 'Get current user'],
          ['get_organization', 'Get organization'], ['get_overview_tickets', 'Get overview tickets'], ['get_shared_draft', 'Get shared draft'], ['get_ticket', 'Get ticket'],
          ['get_ticket_articles', 'Get ticket articles'], ['get_ticket_fields', 'Get ticket fields'], ['get_ticket_history', 'Get ticket history'], ['get_user', 'Get user'],
          ['link_tickets', 'Link tickets'], ['list_overviews', 'List overviews'], ['list_tags', 'List tags'], ['read_attachment', 'Read attachment'], ['save_shared_draft', 'Save shared draft'], ['search_organizations', 'Search organizations'], ['search_tickets', 'Search tickets'], ['search_users', 'Search users'],
          ['send_shared_draft', 'Send shared draft'], ['set_ticket_tags', 'Set ticket tags'], ['update_ticket', 'Update ticket']
        ],
      )
      expect_valid('2025-11-25', 'ListToolsResult', tool_list)

      legacy_request('tools/call', { name: 'echo_text', arguments: { text: 'hello' } }, id: 2)
      expect(json_response['result']).to include('content' => [{ 'type' => 'text', 'text' => 'hello' }], 'structuredContent' => { 'text' => 'hello' }, 'isError' => false)
      expect_valid('2025-11-25', 'CallToolResult', json_response['result'])
      expect_valid_output(tool_list, json_response['result'])
      expect(tool_runs).to eq(['hello'])
    end

    it 'answers an error of a tool as text alone, valid in its revision' do
      legacy_request('tools/call', { name: 'echo_text', arguments: { text: 42 } })

      expect(json_response['result']).to include('isError' => true).and(not_include('structuredContent'))
      expect_valid('2025-11-25', 'CallToolResult', json_response['result'])
    end

    it 'answers a method of a capability the server does not declare as not found' do
      legacy_request('prompts/list')

      expect(json_response['error']).to include('code' => -32_601)
      expect_valid('2025-11-25', 'JSONRPCErrorResponse', json_response)
    end
  end

  describe 'revision 2026-07-28, stateless' do
    it 'describes itself on server/discover' do
      modern_request('server/discover')

      expect(response).to have_http_status(:ok)
      expect(json_response['result']).to include(
        'supportedVersions' => ['2026-07-28'],
        'capabilities'      => { 'tools' => {} },
        'ttlMs'             => 300_000,
        'cacheScope'        => 'private',
        'resultType'        => 'complete',
        '_meta'             => { 'io.modelcontextprotocol/serverInfo' => include('name' => 'zammad', 'version' => Version.get) },
      )
      expect_valid('2026-07-28', 'DiscoverResult', json_response['result'])
    end

    it 'lists the tools with cache hints private to the token and runs one' do
      modern_request('tools/list')
      tool_list = json_response['result']
      expect(tool_list).to include('ttlMs' => 300_000, 'cacheScope' => 'private', 'resultType' => 'complete')
      expect_valid('2026-07-28', 'ListToolsResult', tool_list)

      modern_request('tools/call', { name: 'echo_text', arguments: { text: 'hello' } }, id: 2, name: 'echo_text')
      expect(json_response['result']).to include(
        'content'           => [{ 'type' => 'text', 'text' => 'hello' }],
        'structuredContent' => { 'text' => 'hello' },
        'isError'           => false,
        'resultType'        => 'complete',
        '_meta'             => { 'io.modelcontextprotocol/serverInfo' => include('name' => 'zammad', 'version' => Version.get) },
      )
      expect_valid('2026-07-28', 'CallToolResult', json_response['result'])
      expect_valid_output(tool_list, json_response['result'])
    end

    it 'answers an error of a tool as text alone, valid in its revision' do
      modern_request('tools/call', { name: 'echo_text', arguments: { text: 42 } }, name: 'echo_text')

      expect(json_response['result']).to include('isError' => true).and(not_include('structuredContent'))
      expect_valid('2026-07-28', 'CallToolResult', json_response['result'])
    end

    it 'accepts a tool name in the base64 form of the Mcp-Name header' do
      modern_request('tools/call', { name: 'echo_text', arguments: { text: 'hello' } }, name: "=?base64?#{Base64.strict_encode64('echo_text')}?=")

      expect(json_response.dig('result', 'isError')).to be(false)
    end

    it 'refuses headers that do not match the body with 400 and -32020' do
      modern_request('tools/list', headers: { 'Mcp-Method' => 'tools/call' })

      expect(response).to have_http_status(:bad_request)
      expect(json_response).to include('id' => 1, 'error' => include('code' => -32_020))
      expect_valid('2026-07-28', 'HeaderMismatchError', json_response)

      modern_request('tools/call', { name: 'echo_text', arguments: { text: 'hello' } }, name: 'other_tool')
      expect(json_response.dig('error', 'code')).to eq(-32_020)
      expect(tool_runs).to be_empty
    end

    it 'refuses a version it does not speak with 400 and -32022, naming the ones it speaks' do
      modern_request('tools/list', headers: { 'MCP-Protocol-Version' => '2099-01-01' })

      expect(response).to have_http_status(:bad_request)
      expect(json_response['error']).to include('code' => -32_022, 'data' => include('supported' => ['2026-07-28']))
      expect_valid('2026-07-28', 'UnsupportedProtocolVersionError', json_response)
    end

    it 'answers unknown methods, methods of undeclared capabilities and removed methods with 404 and -32601' do
      %w[unknown/method prompts/list resources/list ping logging/setLevel subscriptions/listen].each do |method|
        modern_request(method)

        expect(response).to have_http_status(:not_found), method
        expect(json_response.dig('error', 'code')).to eq(-32_601)
        expect_valid('2026-07-28', 'MethodNotFoundError', json_response['error'])
      end
    end

    it 'ignores a session id or stream position a client still sends' do
      modern_request('tools/list', headers: { 'Mcp-Session-Id' => 'stale-session', 'Last-Event-ID' => '42' })

      expect(response).to have_http_status(:ok)
      expect(response.headers['Mcp-Session-Id']).to be_nil
    end
  end

  describe 'messages that are no valid request' do
    it 'refuses a request whose id is null, missing or neither a string nor an integer, and runs nothing' do
      [nil, true, 1.5, {}].each do |id|
        mcp_post({ jsonrpc: '2.0', id:, method: 'tools/call', params: { name: 'echo_text', arguments: { text: 'hello' } } }, headers: { 'MCP-Protocol-Version' => '2025-11-25' })
        expect_refusal(:bad_request, 'A request needs an id that is a string or an integer.')
      end

      mcp_post({ jsonrpc: '2.0', method: 'tools/call', params: { name: 'echo_text', arguments: { text: 'hello' } } }, headers: { 'MCP-Protocol-Version' => '2025-11-25' })
      expect_refusal(:bad_request, 'A request needs an id that is a string or an integer.')

      expect(tool_runs).to be_empty
    end

    it 'echoes any string as id, as JSON-RPC allows' do
      ['a.b', 'req:1/x'].each do |id|
        legacy_request('tools/list', id:)

        expect(json_response['id']).to eq(id)
      end
    end

    it 'refuses a batch, a body that is no object and a body that is no JSON' do
      [[{ jsonrpc: '2.0', id: 1, method: 'tools/list' }], 'tools/list'].each do |body|
        mcp_post(body, headers: { 'MCP-Protocol-Version' => '2025-11-25' })

        expect_refusal(:bad_request, 'A message has to be one JSON object.')
      end

      mcp_post(nil, raw: '{"jsonrpc":', headers: { 'MCP-Protocol-Version' => '2025-11-25' })
      expect_error_without_id(:bad_request)
      expect(json_response['error']).to eq('code' => -32_700, 'message' => 'Parse error')
    end

    it 'answers what the gem refuses before it reads the id without an id, as the schema asks' do
      legacy_request('tools/list', headers: { 'Accept' => 'text/html' })
      expect_error_without_id(:not_acceptable)

      modern_request('tools/list', headers: { 'Accept' => 'application/json' })
      expect_error_without_id(:not_acceptable)

      legacy_request('tools/list', headers: { 'Content-Type' => 'text/plain' })
      expect_error_without_id(:unsupported_media_type)
    end

    it 'answers a message without a method or an id without an id, as the schema asks' do
      [{}, { jsonrpc: '2.0' }].each do |body|
        mcp_post(body, headers: { 'MCP-Protocol-Version' => '2025-11-25' })

        expect_error_without_id(:ok)
        expect(json_response.dig('error', 'code')).to eq(-32_600)
      end
    end
  end

  describe 'headers' do
    it 'accepts empty members in the Accept list, as RFC 9110 asks, in both revisions' do
      legacy_request('tools/list', headers: { 'Accept' => ', application/json,, text/event-stream' })
      expect(response).to have_http_status(:ok)
      expect_valid('2025-11-25', 'ListToolsResult', json_response['result'])

      modern_request('tools/list', headers: { 'Accept' => 'application/json,,text/event-stream,' })
      expect(response).to have_http_status(:ok)
      expect_valid('2026-07-28', 'ListToolsResult', json_response['result'])
    end
  end

  describe 'tools' do
    it 'lists only what the token and its user may use, so that two tokens see two lists' do
      calendar = create(:token, user: agent, preferences: { permission: %w[user_preferences.calendar] })

      legacy_request('tools/list')
      expect(json_response.dig('result', 'tools').pluck('name')).to eq(%w[add_internal_note create_article create_ticket echo_text get_current_user get_organization get_overview_tickets get_shared_draft get_ticket get_ticket_articles get_ticket_fields get_ticket_history get_user link_tickets list_overviews list_tags read_attachment save_shared_draft search_organizations search_tickets search_users send_shared_draft set_ticket_tags update_ticket])

      legacy_request('tools/list', token: calendar)
      expect(json_response.dig('result', 'tools')).to eq([])
    end

    it 'lists the tools with what they cannot do' do
      legacy_request('tools/list')
      descriptions = json_response.dig('result', 'tools').to_h { |tool| [tool['name'], tool['description']] }

      expect(descriptions['search_tickets']).to include('created_at:>now-1d', 'Use the filters for customer', 'newest created first')
      expect(descriptions.values_at('get_ticket', 'get_ticket_articles')).to all(include('by which read_attachment reads them'))
      expect(descriptions['create_ticket']).to include('Zammad cannot write the first message in a chat')
    end

    it 'sets every annotation of a read tool and of a write' do
      legacy_request('tools/list')
      annotations = json_response.dig('result', 'tools').to_h { |tool| [tool['name'], tool['annotations']] }

      expect(annotations['echo_text']).to eq('readOnlyHint' => true, 'destructiveHint' => false, 'idempotentHint' => true, 'openWorldHint' => false)
      expect(annotations['add_internal_note']).to eq('readOnlyHint' => false, 'destructiveHint' => false, 'idempotentHint' => false, 'openWorldHint' => false)
      expect(annotations['create_article']).to eq('readOnlyHint' => false, 'destructiveHint' => true, 'idempotentHint' => false, 'openWorldHint' => true)
      expect(annotations['update_ticket']).to eq('readOnlyHint' => false, 'destructiveHint' => true, 'idempotentHint' => true, 'openWorldHint' => false)
      expect(annotations['set_ticket_tags']).to eq('readOnlyHint' => false, 'destructiveHint' => true, 'idempotentHint' => true, 'openWorldHint' => false)
      expect(annotations['list_tags']).to eq('readOnlyHint' => true, 'destructiveHint' => false, 'idempotentHint' => true, 'openWorldHint' => false)
      expect(annotations['save_shared_draft']).to eq('readOnlyHint' => false, 'destructiveHint' => true, 'idempotentHint' => false, 'openWorldHint' => false)
    end

    it 'answers a tool the token may not use like an unknown one' do
      calendar = create(:token, user: agent, preferences: { permission: %w[user_preferences.calendar] })

      legacy_request('tools/call', { name: 'echo_text', arguments: { text: 'hello' } }, token: calendar)

      expect(json_response.dig('error', 'code')).to eq(-32_602)
      expect(tool_runs).to be_empty
    end

    it 'answers arguments that do not fit as a result the model can act on' do
      legacy_request('tools/call', { name: 'echo_text', arguments: { text: 42 } })
      expect(json_response['result']).to include('isError' => true)

      # The gem checks required arguments itself, before the permission check sees the call.
      legacy_request('tools/call', { name: 'echo_text', arguments: {} })
      expect(json_response['result']).to include('isError' => true, 'content' => [{ 'type' => 'text', 'text' => 'Missing required arguments: text' }])

      expect(tool_runs).to be_empty
    end
  end

  # The permission cases of reading a ticket, from outside: the tool's own spec holds the rest.
  describe 'reading a ticket' do
    let(:group)     { create(:group) }
    let(:agent)     { create(:agent, groups: [group]) }
    let(:ticket)    { create(:ticket, group:, title: 'Outlook sync fails after update') }
    let(:not_found) { { 'error' => 'not_found', 'message' => Service::AI::Tool::NOT_FOUND_MESSAGE } }

    before do
      create(:ticket_article, :inbound_email, ticket:, body: 'Since the update, Outlook no longer syncs.', content_type: 'text/plain')
    end

    def names_of(ticket)
      { ticket_number: ticket.number, ticket_id: ticket.id, ticket_url: "#{Setting.get('http_type')}://#{Setting.get('fqdn')}/#ticket/zoom/#{ticket.id}" }
    end

    def read(arguments, token: self.token)
      modern_request('tools/call', { name: 'get_ticket', arguments: }, name: 'get_ticket', token:)
      json_response['result']
    end

    it 'reads a ticket named by its number, its ID or a link, in both revisions, valid in each' do
      modern_request('tools/list')
      tool_list = json_response['result']

      names_of(ticket).each do |name, value|
        result = read({ name => value })

        expect(result).to include('isError' => false, 'structuredContent' => include('ticket' => include('id' => ticket.id, 'url' => end_with("#ticket/zoom/#{ticket.id}"))))
        expect_valid('2026-07-28', 'CallToolResult', result)
        expect(output_schema_errors(tool_list['tools'].find { |tool| tool['name'] == 'get_ticket' }['outputSchema'], result['structuredContent'])).to be_empty
      end

      legacy_request('tools/call', { name: 'get_ticket', arguments: { ticket_number: ticket.number } })
      expect(json_response.dig('result', 'isError')).to be(false)
      expect_valid('2025-11-25', 'CallToolResult', json_response['result'])
    end

    it 'answers a ticket the user may not read, one seen only as its customer and a missing one alike' do
      other    = create(:ticket)
      customer = create(:agent_and_customer, groups: [group])
      owned    = create(:ticket, customer:)
      token    = create(:token, user: customer, preferences: { permission: %w[ticket.agent] })

      names_of(other).each do |name, value|
        expect(JSON.parse(read({ name => value }).dig('content', 0, 'text'))).to eq(not_found)
      end
      expect(JSON.parse(read({ ticket_number: '000' }).dig('content', 0, 'text'))).to eq(not_found)
      expect(JSON.parse(read({ ticket_id: owned.id }, token:).dig('content', 0, 'text'))).to eq(not_found)
    end

    it 'offers nothing to a customer\'s token, nor to a token whose user lost the agent role' do
      customer = create(:customer)
      token    = create(:token, user: customer, preferences: { permission: %w[ticket.agent ticket.customer] })

      legacy_request('tools/list', token:)
      expect(json_response.dig('result', 'tools')).to eq([])
      legacy_request('tools/call', { name: 'get_ticket', arguments: { ticket_id: ticket.id } }, token:)
      expect(json_response.dig('error', 'code')).to eq(-32_602)

      agent.update!(roles: [Role.find_by(name: 'Customer')])
      legacy_request('tools/list')
      expect(json_response.dig('result', 'tools')).to eq([])
    end
  end

  # A write from outside, as the REST API makes it: the tool's own spec holds the permission cases.
  describe 'adding an internal note' do
    let(:group)  { create(:group) }
    let(:agent)  { create(:agent, groups: [group]) }
    let(:ticket) { create(:ticket, group:) }

    it 'adds the note as the token\'s user, in both revisions, valid in each' do
      modern_request('tools/call', { name: 'add_internal_note', arguments: { ticket_number: ticket.number, text: 'Called the customer.' } }, name: 'add_internal_note')
      expect(json_response['result']).to include('isError' => false, 'structuredContent' => include('ticket_id' => ticket.id))
      expect_valid('2026-07-28', 'CallToolResult', json_response['result'])

      legacy_request('tools/call', { name: 'add_internal_note', arguments: { ticket_id: ticket.id, text: 'Waiting for the invoice.' } })
      expect(json_response.dig('result', 'isError')).to be(false)
      expect_valid('2025-11-25', 'CallToolResult', json_response['result'])

      expect(ticket.articles.map { |article| article.slice(:body, :internal, :created_by_id) }).to eq([
                                                                                                        { 'body' => 'Called the customer.', 'internal' => true, 'created_by_id' => agent.id },
                                                                                                        { 'body' => 'Waiting for the invoice.', 'internal' => true, 'created_by_id' => agent.id },
                                                                                                      ])
    end

    it 'records the note in the ticket history as the user\'s, as over the REST API' do
      legacy_request('tools/call', { name: 'add_internal_note', arguments: { ticket_id: ticket.id, text: 'A note.' } })

      entry = History.find_by(history_object: History::Object.lookup(name: 'Ticket::Article'), o_id: ticket.articles.last.id, history_type: History::Type.lookup(name: 'created'))
      expect(entry).to have_attributes(created_by_id: agent.id, sourceable_type: nil)
    end

    it 'lists no note and writes none for a token without the agent permission' do
      calendar = create(:token, user: agent, preferences: { permission: %w[user_preferences.calendar] })

      legacy_request('tools/call', { name: 'add_internal_note', arguments: { ticket_id: ticket.id, text: 'A note.' } }, token: calendar)

      expect(json_response.dig('error', 'code')).to eq(-32_602)
      expect(ticket.articles).to be_empty
    end
  end

  # Preparation and permission matrices live in create_article_spec and article_confirmation_spec.
  describe 'creating articles', performs_jobs: true do
    let(:group) { create(:group, email_address: create(:email_address)) }
    let(:agent)             { create(:agent, groups: [group]) }
    let(:ticket)            { create(:ticket, group:) }
    let(:article_arguments) { { ticket_id: ticket.id, type: 'email', text: 'The fix ships tomorrow.', to: ['customer@example.com'] } }

    def create_article_request(**extra)
      modern_request('tools/call', { name: 'create_article', arguments: article_arguments }.merge(extra),
                     name: 'create_article', capabilities: { elicitation: { form: {} } })
      json_response['result']
    end

    it 'confirms across stateless HTTP requests with schema-valid requests and results' do
      pending = create_article_request
      expect_valid('2026-07-28', 'InputRequiredResult', pending)
      expect(pending.dig('inputRequests', 'confirm', 'params', 'message')).to include('customer@example.com', article_arguments[:text])
      expect(ticket.articles).to be_empty
      result = create_article_request(requestState: pending['requestState'], inputResponses: { confirm: { action: 'accept', content: { confirm: true } } })
      expect_valid('2026-07-28', 'CallToolResult', result)
      expect(result).to include('isError' => false, 'structuredContent' => include('outcome' => 'queued'))
      expect(ticket.articles.count).to eq(1)
      entry = History.find_by(history_object: History::Object.lookup(name: 'Ticket::Article'), o_id: ticket.articles.last.id, history_type: History::Type.lookup(name: 'created'))
      expect(entry).to have_attributes(created_by_id: agent.id, sourceable_type: nil)
    end

    it 'seals the request state, so that the client can neither read nor change it' do
      pending = create_article_request

      expect(pending['requestState']).to start_with('v1.').and(not_include(AI::MCPConfirmation.last.request_id))

      create_article_request(requestState: "#{pending['requestState']}x", inputResponses: { confirm: { action: 'accept', content: { confirm: true } } })
      expect(json_response.dig('error', 'code')).to eq(-32_602)
      expect(ticket.articles).to be_empty
    end

    it 'refuses a request state older than the confirmation lives' do
      pending = create_article_request

      travel 11.minutes
      create_article_request(requestState: pending['requestState'], inputResponses: { confirm: { action: 'accept', content: { confirm: true } } })
      expect(json_response.dig('error', 'code')).to eq(-32_602)
      expect(ticket.articles).to be_empty
    end

    it 'refuses the request state of a call with other arguments' do
      pending = create_article_request

      modern_request('tools/call', { name: 'create_article', arguments: article_arguments.merge(text: 'Something else.'), requestState: pending['requestState'],
                                     inputResponses: { confirm: { action: 'accept', content: { confirm: true } } } },
                     name: 'create_article', capabilities: { elicitation: { form: {} } })
      expect(json_response.dig('error', 'code')).to eq(-32_602)
      expect(ticket.articles).to be_empty
    end

    it 'returns a normal error result after decline without creating or queuing an article' do
      pending = create_article_request
      result = create_article_request(requestState: pending['requestState'], inputResponses: { confirm: { action: 'decline' } })
      expect_valid('2026-07-28', 'CallToolResult', result)
      expect(result['isError']).to be(true)
      expect(ticket.articles).to be_empty
      expect(TicketArticleCommunicateEmailJob).not_to have_been_enqueued
    end

    it 'rejects a revoked token on continuation at the HTTP authentication boundary' do
      pending = create_article_request
      token.update!(persistent: false, expires_at: 1.minute.ago)
      create_article_request(requestState: pending['requestState'], inputResponses: { confirm: { action: 'accept', content: { confirm: true } } })
      expect(response).to have_http_status(:unauthorized)
      expect(ticket.articles).to be_empty
    end

    it 'uses the client-approval path in both revisions when form elicitation is unavailable' do
      legacy_request('tools/call', { name: 'create_article', arguments: article_arguments })
      expect_valid('2025-11-25', 'CallToolResult', json_response['result'])
      expect(json_response.dig('result', 'isError')).to be(false)
      modern_request('tools/call', { name: 'create_article', arguments: article_arguments }, name: 'create_article')
      expect_valid('2026-07-28', 'CallToolResult', json_response['result'])
      expect(json_response.dig('result', 'isError')).to be(false)
      expect(ticket.articles.count).to eq(2)
    end

    it 'does not treat an empty continuation as a fresh call without elicitation' do
      modern_request('tools/call', { name: 'create_article', arguments: article_arguments, inputResponses: {} }, name: 'create_article')
      expect(json_response.dig('result', 'isError')).to be(true)
      expect(ticket.articles).to be_empty
      expect(TicketArticleCommunicateEmailJob).not_to have_been_enqueued
    end

    it 'rejects attachment and internal-note escalation arguments over the wire' do
      legacy_request('tools/call', { name: 'create_article', arguments: article_arguments.merge(attachments: []) })
      expect(json_response.dig('result', 'isError')).to be(true)
      legacy_request('tools/call', { name: 'add_internal_note', arguments: { ticket_id: ticket.id, text: 'Send this.', type: 'email', internal: false, to: ['customer@example.com'] } })
      expect(json_response.dig('result', 'isError')).to be(true)
      expect(ticket.articles).to be_empty
    end
  end

  # A change of a ticket from outside, as the REST API makes it: the tools' own specs hold the rules and the refusals.
  describe 'changing ticket fields' do
    let(:group)  { create(:group) }
    let(:agent)  { create(:agent, groups: [group]) }
    let(:ticket) { create(:ticket, group:, state: Ticket::State.lookup(name: 'open')) }

    it 'lists the fields and changes them as the token\'s user, in both revisions, valid in each' do
      modern_request('tools/call', { name: 'get_ticket_fields', arguments: { ticket_number: ticket.number, field: 'state' } }, name: 'get_ticket_fields')
      expect(json_response['result']).to include('isError' => false, 'structuredContent' => include('fields' => [include('argument' => 'state', 'value' => 'open')]))
      expect_valid('2026-07-28', 'CallToolResult', json_response['result'])

      legacy_request('tools/call', { name: 'update_ticket', arguments: { ticket_id: ticket.id, state: 'closed', owner: 'me' } })
      expect(json_response['result']).to include('isError' => false, 'structuredContent' => include('changes' => include(include('argument' => 'state', 'to' => 'closed'))))
      expect_valid('2025-11-25', 'CallToolResult', json_response['result'])

      expect(ticket.reload).to have_attributes(state: Ticket::State.lookup(name: 'closed'), owner: agent, updated_by: agent)
      entry = History.find_by(history_object: History::Object.lookup(name: 'Ticket'), o_id: ticket.id, history_attribute: History::Attribute.lookup(name: 'state'))
      expect(entry).to have_attributes(created_by_id: agent.id, sourceable_type: nil)
    end

    it 'refuses a change Core Workflow refuses, as an error the client can act on, valid in both revisions' do
      modern_request('tools/call', { name: 'update_ticket', arguments: { ticket_number: ticket.number, state: 'pending reminder' } }, name: 'update_ticket')
      expect(json_response['result']).to include('isError' => true)
      expect(json_response.dig('result', 'content', 0, 'text')).to include('missing_value', 'pending_time')
      expect_valid('2026-07-28', 'CallToolResult', json_response['result'])
      expect(ticket.reload.state.name).to eq('open')
    end

    it 'refuses an owner whose name fits only by a part, with the candidate, valid in the modern revision' do
      create(:agent, firstname: 'Hannah', lastname: 'Quixote', email: 'hannah.quixote@example.com', groups: [group])

      modern_request('tools/call', { name: 'update_ticket', arguments: { ticket_number: ticket.number, owner: 'Quixo', state: 'closed' } }, name: 'update_ticket')
      expect(json_response['result']).to include('isError' => true)
      expect(json_response.dig('result', 'content', 0, 'text')).to include('ambiguous', 'fits only by a part: Hannah Quixote (hannah.quixote@example.com)')
      expect_valid('2026-07-28', 'CallToolResult', json_response['result'])
      expect(ticket.reload.state.name).to eq('open')
    end

    it 'asks for a missing pending time across stateless requests, valid in the modern revision' do
      arguments = { ticket_number: ticket.number, state: 'pending reminder' }

      modern_request('tools/call', { name: 'update_ticket', arguments: }, name: 'update_ticket', capabilities: { elicitation: { form: {} } })
      pending = json_response['result']
      expect_valid('2026-07-28', 'InputRequiredResult', pending)
      expect(pending.dig('inputRequests', 'values', 'params', 'requestedSchema', 'required')).to eq(['pending_time'])

      modern_request('tools/call', { name: 'update_ticket', arguments:, requestState: pending['requestState'], inputResponses: { values: { action: 'accept', content: { pending_time: '2026-10-26T09:00:00Z' } } } },
                     name: 'update_ticket', capabilities: { elicitation: { form: {} } })
      expect_valid('2026-07-28', 'CallToolResult', json_response['result'])
      expect(json_response.dig('result', 'isError')).to be(false)
      expect(ticket.reload).to have_attributes(state: Ticket::State.lookup(name: 'pending reminder'), pending_time: Time.utc(2026, 10, 26, 9))
    end
  end

  # The tags' rules live in set_ticket_tags_spec and list_tags_spec.
  describe 'setting tags' do
    let(:group)  { create(:group) }
    let(:agent)  { create(:agent, groups: [group]) }
    let(:ticket) { create(:ticket, group:) }

    before { Tag::Item.lookup_by_name_and_create('Billing') }

    it 'lists the tags and sets one by its existing name, in both revisions, valid in each' do
      modern_request('tools/call', { name: 'list_tags', arguments: { query: 'bill' } }, name: 'list_tags')
      expect(json_response['result']).to include('isError' => false, 'structuredContent' => include('tags' => ['Billing']))
      expect_valid('2026-07-28', 'CallToolResult', json_response['result'])

      legacy_request('tools/call', { name: 'set_ticket_tags', arguments: { ticket_id: ticket.id, add: ['billing'] } })
      expect(json_response['result']).to include('isError' => false, 'structuredContent' => include('added' => ['Billing']))
      expect_valid('2025-11-25', 'CallToolResult', json_response['result'])
      expect(ticket.tag_list).to eq(['Billing'])
    end
  end

  # The draft's rules live in save_shared_draft_spec.
  describe 'saving shared drafts' do
    let(:group)           { create(:group) }
    let(:agent)           { create(:agent, groups: [group]) }
    let(:ticket)          { create(:ticket, group:) }
    let(:draft_arguments) { { ticket_id: ticket.id, type: 'email', text: 'The fix ships tomorrow.', to: ['customer@example.com'] } }

    def save_draft_request(**extra)
      modern_request('tools/call', { name: 'save_shared_draft', arguments: draft_arguments }.merge(extra),
                     name: 'save_shared_draft', capabilities: { elicitation: { form: {} } })
      json_response['result']
    end

    it 'saves a draft in both revisions, and asks across stateless requests before it replaces one' do
      legacy_request('tools/call', { name: 'save_shared_draft', arguments: draft_arguments })
      expect_valid('2025-11-25', 'CallToolResult', json_response['result'])
      expect(json_response['result']).to include('isError' => false, 'structuredContent' => include('outcome' => 'created'))

      legacy_request('tools/call', { name: 'save_shared_draft', arguments: draft_arguments.merge(text: 'Another reply.') })
      expect(json_response['result']).to include('isError' => true, 'content' => [include('text' => include('shared_draft_exists'))])

      pending = save_draft_request(arguments: draft_arguments.merge(text: 'Another reply.'))
      expect_valid('2026-07-28', 'InputRequiredResult', pending)
      result = save_draft_request(arguments: draft_arguments.merge(text: 'Another reply.'), requestState: pending['requestState'],
                                  inputResponses: { values: { action: 'accept', content: { overwrite: true } } })
      expect_valid('2026-07-28', 'CallToolResult', result)
      expect(result).to include('isError' => false, 'structuredContent' => include('outcome' => 'replaced'))
      expect(ticket.reload.shared_draft.body).to eq('Another reply.')
      expect(ticket.articles).to be_empty
    end
  end

  # A new ticket from outside, as the REST API creates one: the tool's own spec holds the rules and the refusals.
  describe 'creating tickets' do
    let(:group)     { create(:group, name: 'Support') }
    let(:agent)     { create(:agent, groups: [group]) }
    let(:customer)  { create(:customer, email: 'carla@example.com') }
    let(:arguments) { { customer: customer.email, title: 'Printer broken', group: 'Support', message: 'phone_in', text: 'Carla called.' } }

    it 'lists the fields of a new ticket and creates one with a note as the token\'s user, valid in both revisions' do
      modern_request('tools/call', { name: 'get_ticket_fields', arguments: { group: 'Support' } }, name: 'get_ticket_fields')
      expect(json_response['result']).to include('isError' => false, 'structuredContent' => include('fields' => include(include('argument' => 'customer'))))
      expect_valid('2026-07-28', 'CallToolResult', json_response['result'])

      legacy_request('tools/call', { name: 'create_ticket', arguments: arguments.merge(message: 'note') })
      expect(json_response['result']).to include('isError' => false, 'structuredContent' => include('message' => 'note', 'outcome' => 'saved'))
      expect_valid('2025-11-25', 'CallToolResult', json_response['result'])
      expect(Ticket.find_by(title: 'Printer broken')).to have_attributes(customer:, created_by_id: agent.id)
    end

    it 'asks to confirm a first message the customer can read across stateless requests, valid in the modern revision' do
      modern_request('tools/call', { name: 'create_ticket', arguments: }, name: 'create_ticket', capabilities: { elicitation: { form: {} } })
      pending = json_response['result']
      expect_valid('2026-07-28', 'InputRequiredResult', pending)
      expect(Ticket.find_by(title: 'Printer broken')).to be_nil

      modern_request('tools/call', { name: 'create_ticket', arguments:, requestState: pending['requestState'], inputResponses: { confirm: { action: 'accept', content: { confirm: true } } } },
                     name: 'create_ticket', capabilities: { elicitation: { form: {} } })
      expect_valid('2026-07-28', 'CallToolResult', json_response['result'])
      expect(json_response.dig('result', 'isError')).to be(false)
      expect(Ticket.find_by(title: 'Printer broken').articles.reorder(:id).first.internal).to be(false)
    end
  end

  # The search from outside: the tool's own spec holds the rest.
  describe 'finding tickets' do
    let(:group) { create(:group) }
    let(:agent) { create(:agent, groups: [group]) }

    before do
      ticket = create(:ticket, group:, title: 'Outlook sync fails after update')
      create(:ticket_article, :inbound_email, ticket:, body: 'Since the update, Outlook no longer syncs.', content_type: 'text/plain')
    end

    def search(arguments)
      modern_request('tools/call', { name: 'search_tickets', arguments: }, name: 'search_tickets')
      json_response['result']
    end

    it 'finds a ticket by its words, valid in its revision' do
      result = search({ query: 'outlook' })

      expect(result['structuredContent']['tickets']).to contain_exactly(include('title' => 'Outlook sync fails after update', 'url' => be_present))
      expect_valid('2026-07-28', 'CallToolResult', result)
    end

    it 'lists the newest tickets for null arguments, a wildcard or nothing to search by' do
      create(:ticket, group:, title: 'Older ticket', created_at: 1.day.ago)
      create(:ticket, group: create(:group), title: 'Ticket of another group')

      [nil, {}, { query: '*' }, { query: '?' }, { query: ' ' }].each do |arguments|
        result = search(arguments)

        expect(result).not_to include('isError' => true), arguments.inspect
        expect(result['structuredContent']['tickets'].pluck('title')).to eq(['Outlook sync fails after update', 'Older ticket']), arguments.inspect
      end
    end

    context 'with Elasticsearch', searchindex: true do
      before do
        create(:ticket, group:, title: 'Outlook sync failed last week', created_at: 1.week.ago)
        searchindex_model_reload([Ticket])
      end

      it "finds tickets by Zammad's search syntax and answers a broken query as a failed search" do
        found  = search({ query: 'outlook AND created_at:>now-1d' })
        broken = search({ query: 'title:(outlook' })

        expect(found['structuredContent']['tickets'].pluck('title')).to eq(['Outlook sync fails after update'])
        expect(broken).to include('isError' => true)
        expect(broken.dig('content', 0, 'text')).to include('The search could not run')
        expect_valid('2026-07-28', 'CallToolResult', broken)
      end
    end
  end

  # The overviews within the token, from outside: the tools' own specs hold the rest.
  describe 'reading overviews' do
    let(:group)  { create(:group) }
    let(:agent)  { create(:agent, groups: [group]) }
    let!(:mine)  { create(:ticket, group:, owner: agent) }

    before { create(:ticket, group: create(:group), owner: agent) }

    def call(name, arguments, token: self.token)
      modern_request('tools/call', { name:, arguments: }, name:, token:)
      json_response['result']
    end

    it 'lists the overviews and reads one by its name, valid in its revision' do
      listed = call('list_overviews', {})
      read   = call('get_overview_tickets', { overview: 'My Assigned Tickets' })

      expect(listed['structuredContent']['overviews'].first).to include('name' => 'My Assigned Tickets', 'ticket_count' => 1, 'url' => end_with('#ticket/view/my_assigned'))
      expect(read['structuredContent']['tickets']).to contain_exactly(include('id' => mine.id, 'url' => be_present))
      expect_valid('2026-07-28', 'CallToolResult', listed)
      expect_valid('2026-07-28', 'CallToolResult', read)
    end

    it 'answers an unknown name as an error with the overviews, never as an empty overview' do
      result = call('get_overview_tickets', { overview: 'VIP queue' })

      expect(result).to include('isError' => true)
      expect(JSON.parse(result.dig('content', 0, 'text'))).to include('error' => 'invalid_value', 'message' => include('My Assigned Tickets'))
    end

    it 'offers neither tool to a customer\'s token' do
      customer = create(:customer)
      token    = create(:token, user: customer, preferences: { permission: %w[ticket.customer] })

      modern_request('tools/list', token:)
      expect(json_response.dig('result', 'tools').pluck('name')).not_to include('list_overviews', 'get_overview_tickets')

      modern_request('tools/call', { name: 'list_overviews', arguments: {} }, name: 'list_overviews', token:)
      expect(json_response.dig('error', 'code')).to eq(-32_602)
    end
  end

  # The knowledge base within the token, from outside: the tools' own specs hold the rest.
  describe 'finding knowledge base answers' do
    let(:agent) { create(:admin) }
    let(:category)   { create(:knowledge_base_category) }
    let!(:published) { create(:knowledge_base_answer, :published, category:, translation_attributes: { title: 'Outlook sync after an update' }) }
    let!(:draft)     { create(:knowledge_base_answer, category:, translation_attributes: { title: 'Outlook sync, unreleased' }) }

    def tool_call(name, arguments, permissions)
      token = create(:token, user: agent, preferences: { permission: permissions })
      modern_request('tools/call', { name:, arguments: }, name:, token:)
      json_response['result']
    end

    it 'finds published answers by words and reads no draft with a reader\'s token, valid in its revision' do
      result = tool_call('search_knowledge_base', { query: 'Outlook sync' }, %w[ticket.agent knowledge_base.reader])

      expect(result['structuredContent']).to include('mode' => 'keyword', 'answers' => [include('id' => published.id, 'url' => be_present)])
      expect_valid('2026-07-28', 'CallToolResult', result)

      expect(tool_call('get_knowledge_base_answer', { answer_id: draft.id }, %w[ticket.agent knowledge_base.reader])).to include('isError' => true)
      expect(tool_call('get_knowledge_base_answer', { answer_id: draft.id }, %w[ticket.agent knowledge_base.editor])).to include('isError' => false)
    end
  end
end
