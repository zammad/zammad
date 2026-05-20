# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# oauth2 2.x introduced auth-sanitizer as a dependency. That gem defines
# `module Auth` at the top level, which conflicts with Zammad's `class Auth`.
# We save the Auth::Sanitizer module object before removing the conflicting
# constant. Then config/initializers/auth_sanitizer_compat.rb will put it at
# the expected place after autoloading lib/auth.rb.
return if !defined?(Auth) || !Auth.instance_of?(Module)

AuthSanitizer = Auth::Sanitizer
Object.send(:remove_const, :Auth)
