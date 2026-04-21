# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Rack::Middleware
  class SecureContext
    def initialize(app)
      @app = app
    end

    def call(env)
      if Session.secure_flag?
        mark_as_https(env)
      end

      @app.call(env)
    end

    private

    def mark_as_https(env)
      # This flag marks Rails environment as SSL, forcing secure flag on cookies.
      # But it does not override request.ssl?.
      # Thus non-HTTPS requests will not be marked as SSL, and secure cookies won't be set.
      env['action_dispatch.ssl'] = true
    end
  end
end
