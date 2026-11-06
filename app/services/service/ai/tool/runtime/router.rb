# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Knows the tools and which of them the harness and the MCP server offer. Concrete subclasses of Service::AI::Tool
# are discovered without a registry; Service::AI::Tool::Runtime::PerformCall and the tools offered to the model or the
# MCP client use the same rule, so that what is offered and what runs cannot drift apart.
class Service::AI::Tool::Runtime::Router
  def self.tools
    # Only classes still reachable by their name: a tool class that a spec defined and removed again stays among the
    # descendants until it is garbage collected.
    Service::AI::Tool.descendants
      .select { |tool| tool.name.present? && tool.name.safe_constantize.equal?(tool) }
      .sort_by(&:tool_name)
  end

  def self.find(name)
    tools.find { |tool| tool.tool_name == name.to_s }
  end

  # @param user [User, nil] as whom the tool would run, loaded freshly by the caller
  # @param surface [Symbol] where the tool would run: :harness or :mcp
  # @param audience [AI::Harness::Audience, nil] the audience of the run, in the harness; nobody runs a conversation
  #   over MCP, so there it is the MCP projection and the token that bound the tools
  # @param token [Token, nil] the personal access token of an MCP request, which narrows the user's permissions
  def self.offered?(tool, user:, surface:, audience: nil, token: nil)
    tool.declared? &&
      confirmable?(tool, surface:) &&
      offered_on?(tool, surface:, audience:) &&
      user.present? && user.active? &&
      permitted?(tool, user:, token:) &&
      tool.usable_by?(user) &&
      tool.available?
  end

  # The tools the model or the MCP client may call; each gives its definition (Service::AI::Tool.definition).
  #
  # @return [Array<Class>] subclasses of Service::AI::Tool
  def self.offered_tools(user:, surface:, audience: nil, token: nil)
    tools.select { |tool| offered?(tool, user:, surface:, audience:, token:) }
  end

  def self.offered_on?(tool, surface:, audience:)
    case surface
    when :harness
      tool.offered_in?(:harness) && tool.audience?(audience)
    when :mcp
      tool.offered_in?(:mcp)
    else
      raise ArgumentError, "unknown surface: #{surface.inspect}"
    end
  end
  private_class_method :offered_on?

  # A write runs once the user confirmed it. An MCP client asks its user itself, as the tool's annotations tell it to; the
  #   harness has no confirmation yet, and a write offered there would be called and never run.
  def self.confirmable?(tool, surface:)
    !tool.write? || surface == :mcp
  end
  private_class_method :confirmable?

  # Without a token the caller's context stays as it is: a request a token authenticated keeps narrowing the user.
  def self.permitted?(tool, user:, token:)
    return user.permissions?(tool.tool_permission) if token.nil?

    UserInfo.with_token(token) { user.permissions?(tool.tool_permission) }
  end
  private_class_method :permitted?
end
