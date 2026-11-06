# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Rack::Middleware
  # Keeps a body the MCP server refuses anyway out of memory: Rails reads and parses a JSON body before any controller
  #   code runs. The body is replaced by an empty one and flagged, so that MCPController still decides what to answer.
  class MCPBodyLimit
    PATH      = '/mcp'.freeze
    LIMIT     = MCP::Server::Transports::StreamableHTTPTransport::DEFAULT_MAX_REQUEST_BYTES
    TOO_LARGE = 'zammad.mcp_body_too_large'.freeze

    def initialize(app)
      @app = app
    end

    def call(env)
      limit_body(env) if env['REQUEST_METHOD'] == 'POST' && mcp_path?(env['PATH_INFO'])

      @app.call(env)
    end

    private

    # Normalized as the router does, which serves /mcp/ and //mcp as well.
    def mcp_path?(path)
      ActionDispatch::Journey::Router::Utils.normalize_path(path) == PATH
    end

    # Whatever Content-Length claims, at most one byte more than the limit is read.
    def limit_body(env)
      body = env['CONTENT_LENGTH'].to_i > LIMIT ? nil : env['rack.input']&.read(LIMIT + 1).to_s

      if body.nil? || body.bytesize > LIMIT
        env[TOO_LARGE] = true
        body           = ''
      end

      env['rack.input']     = StringIO.new(body)
      env['CONTENT_LENGTH'] = body.bytesize.to_s
    end
  end
end
