# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rack/middleware/secure_context'

Rails
  .application
  .config
  .middleware
  .insert_after ActionDispatch::Cookies, Rack::Middleware::SecureContext
