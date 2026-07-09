# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

if Rails.env.development? && ['Node.js (V8)', 'Persistent Node.js (V8)'].exclude?(ExecJS.runtime&.name)
  raise "The CoffeeScript assets cannot be compiled with the installed JS runtime '#{ExecJS.runtime.name}'. Please use Node.js instead."
end
