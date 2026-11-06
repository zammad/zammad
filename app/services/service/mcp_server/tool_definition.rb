# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# How a tool of the tool layer is offered over MCP: its definition for tools/list, whose calls run only through
# Service::MCPServer::CallTool.
class Service::MCPServer::ToolDefinition < Service::Base
  attr_reader :tool, :user, :token

  # @param tool [Class] a subclass of Service::AI::Tool, offered over MCP
  # @param user [User] as whom the tool runs
  # @param token [Token] the personal access token of the request
  def initialize(tool:, user:, token:)
    @tool  = tool
    @user  = user
    @token = token
  end

  # @return [Class] an MCP::Tool for the gem's server
  def execute
    tool_class = tool
    acting     = { user:, token: }

    MCP::Tool.define(
      name:          tool.tool_name,
      title:         tool.tool_title,
      description:   tool.description_for(:mcp),
      input_schema:  tool.input_schema(surface: :mcp),
      output_schema: tool.tool_output_schema,
      annotations:,
    ) do |server_context:, **arguments|
      Service::MCPServer::CallTool.execute(tool: tool_class, arguments:, server_context:, **acting)
    end
  end

  private

  # Every hint is set: omitted hints have permissive protocol defaults. Outbound tools override the additive-write hints.
  def annotations
    {
      read_only_hint:   !tool.write?,
      destructive_hint: false,
      idempotent_hint:  !tool.write?,
      open_world_hint:  false,
    }.merge(tool.tool_mcp_annotations)
  end
end
