# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

if Rails.env.development? && (ExecJS.runtime&.name != 'Node.js (V8)')
  raise "The CoffeeScript assets cannot be compiled with the installed JS runtime '#{ExecJS.runtime.name}'. Please use Node.js instead."
end
