# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# A call of a tool over MCP: only through the permission check, as the token's user and with the token's limits.
class Service::MCPServer::CallTool < Service::Base
  # A yes asks for nothing more: the client's Accept is the yes.
  YES = { type: 'object', properties: {} }.freeze

  attr_reader :tool, :arguments, :user, :token, :server_context

  # @param tool [Class] a subclass of Service::AI::Tool
  # @param arguments [Hash] as the client sent them
  # @param user [User] as whom the tool runs
  # @param token [Token] the personal access token of the request
  def initialize(tool:, arguments:, user:, token:, server_context: nil)
    @tool      = tool
    @arguments = arguments
    @user      = user
    @token     = token
    @server_context = server_context
  end

  # @return [MCP::Tool::Response] the tool's text, and the hash a tool with an output schema returns; an error is a
  #   result the model can act on
  def execute
    result = perform_call
    return confirmation_response(result) if result.status == 'confirmation_required'
    return text_response(result.text, error: true) if !result.ok?
    return text_response(result.text) if tool.tool_output_schema.nil?

    structured = Service::MCPServer::StructuredContent.of(result.content)
    text_response([result.text, structured.links_text].compact.join("\n\n"), structured_content: structured.content)
  end

  private

  def perform_call
    tool_call = AI::Provider::Completion::ToolCall.new(id: SecureRandom.uuid, name: tool.tool_name, arguments: arguments.deep_stringify_keys)
    options = { user:, tool_call:, surface: :mcp, token: }
    if server_context
      options[:confirmation] = Service::MCPServer::Confirmation.asker(user:, token:, tool_name: tool.tool_name, server_context:)
    end
    Service::AI::Tool::Runtime::PerformCall.execute(**options)
  end

  def confirmation_response(result)
    MCP::Server::InputRequiredResult.new(
      request_state:  result.content.fetch(:request_state),
      input_requests: {
        result.content.fetch(:input_key, 'confirm') => {
          method: 'elicitation/create',
          params: {
            mode:            'form',
            message:         result.text,
            requestedSchema: result.content[:requested_schema] || YES,
          },
        },
      },
    )
  end

  # An error goes out without structured content: clients check it against the output schema even then.
  def text_response(text, error: false, structured_content: nil)
    MCP::Tool::Response.new([{ type: 'text', text: }], error:, structured_content:, meta: server_info)
  end

  # The result names the server, as the specification suggests for every result of 2026-07-28.
  def server_info
    { MCP::RequestEnvelope::SERVER_INFO_META_KEY => { name: 'zammad', title: 'Zammad', version: Version.get } }
  end
end
