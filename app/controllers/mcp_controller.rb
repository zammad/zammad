# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Zammad's own MCP server, over Streamable HTTP, for AI clients that authenticate with a personal access token. The
# controller decides whether a request gets in; Service::MCPServer::HandleRequest answers it.
class MCPController < ApplicationController
  # A request without any token: the challenge carries no error code (RFC 6750, section 3.1).
  class TokenMissing < StandardError; end

  # Written for the client, like every text a tool returns, so not translated.
  # rubocop:disable Zammad/DetectTranslatableString
  CHALLENGE         = 'Bearer realm="Zammad"'.freeze
  CHALLENGE_INVALID = 'Bearer realm="Zammad", error="invalid_token"'.freeze
  MESSAGES          = {
    address_refused:    'This address is not allowed.',
    on_behalf_refused:  'Acting on behalf of another user is not supported.',
    switched_off:       'The MCP server is switched off.',
    token_missing:      'A personal access token is required.',
    token_invalid:      'The access token is invalid.',
    body_too_large:     'The request body is too large.',
    method_not_allowed: 'Only POST is supported.',
    parse_error:        'Parse error',
    internal_error:     'Internal error',
  }.freeze
  # rubocop:enable Zammad/DetectTranslatableString

  # Only a personal access token authenticates here: there is no session to keep up to date or to protect against
  #   forgery.
  skip_before_action :session_update, :user_device_log, :verify_csrf_token
  skip_after_action :set_csrf_token_headers

  # Prepended in reverse: the address is checked before anything else, as the transport specification asks.
  prepend_before_action :authenticate_with_personal_access_token!, only: :handle
  prepend_before_action :verify_address!

  # Every failure answers as JSON-RPC, never with the body of the REST API. The last declared handler is tried first.
  rescue_from StandardError, with: :internal_server_error
  rescue_from ActionController::BadRequest, ActionDispatch::Http::Parameters::ParseError, with: :bad_request
  rescue_from TokenMissing, with: :token_missing
  rescue_from Exceptions::NotAuthorized, with: :token_invalid
  rescue_from Exceptions::Forbidden, with: :refused

  def handle
    return render_error(:content_too_large, MESSAGES[:body_too_large]) if request.env[Rack::Middleware::MCPBodyLimit::TOO_LARGE]

    status, headers, body = Service::MCPServer::HandleRequest.execute(request:, user: current_user_real, token: @_token)

    # Handed over one by one: a rendered body would turn the empty answer to a notification into "null".
    self.status = status
    headers.each { |name, value| response.headers[name] = value }
    self.response_body = body
  end

  def method_not_allowed
    response.headers['Allow'] = 'POST'
    render_error(:method_not_allowed, MESSAGES[:method_not_allowed])
  end

  private

  def verify_address!
    return if Service::MCPServer::Addresses.allowed?(host: request.headers['Host'], origin: request.headers['Origin'])

    raise Exceptions::Forbidden, MESSAGES[:address_refused]
  end

  def authenticate_with_personal_access_token!
    # The token's limits would be lost to the user acting for someone else.
    raise Exceptions::Forbidden, MESSAGES[:on_behalf_refused] if request_header_from.present?
    raise Exceptions::Forbidden, MESSAGES[:switched_off] if !Setting.get('api_mcp_access')

    token_string = ActionController::HttpAuthentication::Token.token_and_options(request)&.first
    raise TokenMissing if token_string.blank?

    return if authentication_check_api_token(token_string) && @_token

    raise Exceptions::NotAuthorized, MESSAGES[:token_invalid]
  end

  def token_missing(_error)
    response.headers['WWW-Authenticate'] = CHALLENGE
    render_error(:unauthorized, MESSAGES[:token_missing])
  end

  def token_invalid(error)
    response.headers['WWW-Authenticate'] = CHALLENGE_INVALID
    render_error(:unauthorized, error.message)
  end

  def refused(error)
    render_error(:forbidden, error.message)
  end

  # Rails parses a JSON body before the action, so a broken one ends up here and not with the gem.
  def bad_request(_error)
    render_error(:bad_request, MESSAGES[:parse_error], code: JsonRpcHandler::ErrorCode::PARSE_ERROR)
  end

  def internal_server_error(error)
    logger.error error
    render_error(:internal_server_error, MESSAGES[:internal_error], code: JsonRpcHandler::ErrorCode::INTERNAL_ERROR)
  end

  # A JSON-RPC error without an id, as the transport allows for an answer that belongs to no request. A refusal can
  #   come before the transaction handling, whose cleanup of the user context would then not run.
  def render_error(status, text, code: JsonRpcHandler::ErrorCode::INVALID_REQUEST)
    UserInfo.reset
    render json: { jsonrpc: '2.0', error: { code:, message: text } }, status:
  end
end
