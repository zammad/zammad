# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Compile assets via a single persistent node process instead of one node
#   process per compile call (see lib/core_ext/execjs/persistent_node_runtime.rb).
# An explicitly configured runtime (EXECJS_RUNTIME=...) takes precedence.
if defined?(ExecJS) && ENV['EXECJS_RUNTIME'].blank?
  runtime = ExecJS::PersistentNodeRuntime.new
  ExecJS.runtime = runtime if runtime.available?
end
