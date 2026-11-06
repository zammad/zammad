# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# The permission check: the only way a tool runs. Every refusal and every failure is a result the model can act on.
class Service::AI::Tool::Runtime::PerformCall < Service::Base
  QUOTE_LENGTH = 500

  attr_reader :user, :tool_call, :surface, :audience, :token, :tool_names, :context_object, :run, :confirmation

  # @param user [User] as whom the tool runs
  # @param tool_call [AI::Provider::Completion::ToolCall] the call the model asked for, with the text it sent when the
  #   arguments were no JSON object
  # @param surface [Symbol] where the call comes from: :harness or :mcp
  # @param audience [AI::Harness::Audience, nil] the audience of the run, in the harness
  # @param token [Token, nil] the personal access token of an MCP request: its limits hold for everything the tool
  #   does, also where a service loads the user again
  # @param tool_names [Array<String>, nil] the tools the caller offered; a call of any other one is refused, and nil
  #   leaves it to the router
  # @param context_object [String, nil] the global ID of the conversation's starting object, for tools that load it
  # @param run [AI::Harness::Run, nil] the run that calls the tool, for tools that need it
  def initialize(user:, tool_call:, surface:, audience: nil, token: nil, tool_names: nil, context_object: nil, run: nil, confirmation: nil)
    @user           = user
    @tool_call      = tool_call
    @surface        = surface
    @audience       = audience
    @token          = token
    @tool_names     = tool_names
    @context_object = context_object
    @run            = run
    @confirmation   = confirmation
  end

  # @return [Service::AI::Tool::Runtime::Result]
  def execute
    tool = Service::AI::Tool::Runtime::Router.find(tool_call.name)

    # Permissions, policies and SQL results are cached for a whole request or job, and a change made by another
    #   request clears neither cache here; read fresh, a revoked permission applies to the very next call.
    Auth::RequestCache.clear
    ActiveRecord::Base.uncached do
      acting_user = User.find_by(id: user&.id)

      with_token { refusal(tool, acting_user) || perform(tool, acting_user) }
    end
  end

  private

  def refusal(tool, acting_user)
    # Not offered and not permitted read the same: the model is never told about a tool it may not use.
    return unknown_tool if tool.nil? || !offered?(tool, acting_user)
    return broken_call if tool_call.invalid?

    errors = tool.argument_errors(arguments, surface:)
    Service::AI::Tool::Runtime::Result.error('invalid_arguments', errors.join('; ')) if errors.any?
  end

  # The router still checks every call, so that a permission revoked mid-run refuses.
  def offered?(tool, acting_user)
    (tool_names.nil? || tool_names.include?(tool.tool_name)) && Service::AI::Tool::Runtime::Router.offered?(tool, user: acting_user, surface:, audience:)
  end

  def with_token(&)
    return yield if token.nil?

    UserInfo.with_token(token, &)
  end

  def arguments
    tool_call.arguments.deep_stringify_keys
  end

  def perform(tool, acting_user)
    options = { arguments:, context_object:, run:, surface: }
    options[:confirmation] = confirmation if confirmation
    Service::AI::Tool::Runtime::Result.from(tool.with_current_user(acting_user).execute(**options))
  rescue Pundit::NotAuthorizedError, Exceptions::Forbidden, ActiveRecord::RecordNotFound
    Service::AI::Tool::Runtime::Result.error('not_found', tool.not_found_message)
  rescue Service::AI::Tool::NoContextObjectError, Service::AI::Tool::NoRunError => e
    Service::AI::Tool::Runtime::Result.error('not_found', e.message)
  rescue Service::AI::Tool::NotNamedError => e
    Service::AI::Tool::Runtime::Result.error('not_named', e.message)
  rescue Service::AI::Tool::ReadOnlyError => e
    Service::AI::Tool::Runtime::Result.error('read_only', e.message)
  rescue Service::AI::Tool::AmbiguousNameError => e
    Service::AI::Tool::Runtime::Result.error('ambiguous', e.message)
  rescue => e
    # The exception's message stays in the log: it may name internals the model and the chat must not see.
    Rails.logger.error "AI tool #{tool.tool_name} failed: #{e.class}: #{e.message}"
    Service::AI::Tool::Runtime::Result.error('execution_failed', "The tool #{tool.tool_name} failed. Try another way, or tell the user that it failed.")
  end

  def unknown_tool
    Service::AI::Tool::Runtime::Result.error('unknown_tool', "There is no tool called '#{tool_call.name}'.")
  end

  def broken_call
    Service::AI::Tool::Runtime::Result.error('invalid_arguments', "The arguments are no JSON object: #{tool_call.raw_arguments.to_s.truncate(QUOTE_LENGTH)}. Call the tool again with its arguments as one JSON object.")
  end
end
