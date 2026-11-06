# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rack/middleware/mcp_body_limit'

# The MCP gem answers a client with a generic error and hands the exception here: its transport reports to this global
#   reporter, not to the one of a server. A client's own mistake, such as an unknown tool, is answered as such and not
#   logged; the name it sent is the client's text.
MCP.configure do |config|
  config.exception_reporter = lambda do |exception, _server_context|
    if exception.is_a?(MCP::Server::RequestHandlerError)
      next if exception.error_type != :internal_error || exception.original_error.nil?

      exception = exception.original_error
    end

    Rails.logger.error "MCP server: #{exception.class}: #{exception.message.inspect}"
  end
end

Rails.application.config.middleware.use Rack::Middleware::MCPBodyLimit
