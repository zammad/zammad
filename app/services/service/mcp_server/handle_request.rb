# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Zammad's own MCP server, for one request a personal access token authenticated: the official gem speaks the
# protocol, the tool layer runs the tools. Built per request, as the gem expects when the tools differ per user, so
# nothing survives between requests and any worker can answer any of them.
class Service::MCPServer::HandleRequest < Service::Base
  # How long a client may reuse the tool list before asking again; every call is still checked, so a permission revoked
  #   meanwhile refuses it.
  TOOLS_TTL_MS = 5.minutes.in_milliseconds

  # Written for the client, like every text a tool returns, so not translated.
  # rubocop:disable Zammad/DetectTranslatableString
  NOT_AN_OBJECT      = 'A message has to be one JSON object.'.freeze
  REQUEST_ID_INVALID = 'A request needs an id that is a string or an integer.'.freeze
  # rubocop:enable Zammad/DetectTranslatableString

  attr_reader :request, :user, :token

  # @param request [ActionDispatch::Request]
  # @param user [User] as whom the tools run
  # @param token [Token] the personal access token that authenticated the request
  def initialize(request:, user:, token:)
    @request = request
    @user    = user
    @token   = token
  end

  # @return [Array] the Rack response: status, headers and body
  def execute
    refusal = message_refusal
    return refused(refusal) if refusal

    transport.handle_request(rack_request)
  end

  private

  # A batch or a scalar would get an answer whose id the specification does not allow, and a request needs an id:
  #   without one, or with null, a call would run and nobody could get its answer. A body that is no JSON at all is
  #   left to the gem, which answers it as the transport asks.
  def message_refusal
    message = JSON.parse(request.raw_post)
    return NOT_AN_OBJECT if !message.is_a?(Hash)
    return if !message['method'].is_a?(String) || message['method'].start_with?('notifications/')

    REQUEST_ID_INVALID if !message['id'].is_a?(String) && !message['id'].is_a?(Integer)
  rescue JSON::ParserError
    nil
  end

  # A JSON-RPC error without an id, as the transport allows for an answer that belongs to no request.
  def refused(text)
    body = { jsonrpc: '2.0', error: { code: JsonRpcHandler::ErrorCode::INVALID_REQUEST, message: text } }

    [400, { 'content-type' => 'application/json' }, [body.to_json]]
  end

  # Stateless: a session the client remembers from another server, or a stream to resume, means nothing here. The gem
  #   reads the body itself, which Rails has read already.
  def rack_request
    env = request.env.except('HTTP_MCP_SESSION_ID', 'HTTP_LAST_EVENT_ID')

    Rack::Request.new(env.merge('rack.input' => StringIO.new(request.raw_post)))
  end

  def transport
    MCP::Server::Transports::StreamableHTTPTransport.new(
      server,
      stateless:                  true,
      enable_json_response:       true,
      serve_subscriptions_listen: false,
      allowed_hosts:              Service::MCPServer::Addresses.hosts,
      allowed_origins:            Service::MCPServer::Addresses.origins,
    )
  end

  def server
    MCP::Server.new(
      name:                   'zammad',
      title:                  'Zammad',
      version:                Version.get,
      tools:,
      capabilities:           { tools: {} },
      ttl_ms:                 TOOLS_TTL_MS,
      cache_scope:            'private',
      configuration:          MCP::Configuration.new(validate_tool_call_arguments: false),
      request_state_security:,
    )
  end

  # The gem seals the request state a client echoes back, so that it can neither read nor change it, and binds it to
  #   the tool and the arguments of the call. The key comes from the installation's secret, so that any worker opens it.
  def request_state_security
    key = OpenSSL::KDF.hkdf(Setting.get('application_secret'), salt: 'zammad', info: 'mcp_request_state', length: 32, hash: 'SHA256')

    MCP::Server::RequestStateSecurity.new(key:, ttl: Service::MCPServer::Confirmation::TTL.to_i)
  end

  def tools
    Service::AI::Tool::Runtime::Router.offered_tools(user:, surface: :mcp, token:).map do |tool|
      Service::MCPServer::ToolDefinition.execute(tool:, user:, token:)
    end
  end
end
