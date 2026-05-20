# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# oauth2 2.x introduced auth-sanitizer as a dependency. That gem defines
# `module Auth` at the top level, which conflicts with Zammad's `class Auth`.
# That module was saved to a temporary constant in
# config/pre_initializers/auth_sanitizer_compat.rb. Now we need to put it
# back where it belongs.
return if !defined?(AuthSanitizer)

require 'auth'
Auth.const_set(:Sanitizer, AuthSanitizer)
