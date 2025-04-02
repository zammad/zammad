# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

worker_count = Integer(ENV['WEB_CONCURRENCY'] || 0)
workers worker_count

threads_count_min = Integer(ENV['MIN_THREADS'] || 5)
threads_count_max = Integer(ENV['MAX_THREADS'] || 30)
threads threads_count_min, threads_count_max

environment ENV.fetch('RAILS_ENV', 'development')

preload_app!

# Teach pumactl to use 'SIGWINCH' instead of 'SIGINFO', because the latter is not available on Linux.
if defined?(Puma::ControlCLI) && Zammad::ProcessDebug.enable_thread_status_handler?
  # Suppress const redefinition warning (can't use silence_warnings from Rails here).
  old_verbose = $VERBOSE
  $VERBOSE = nil
  Puma::ControlCLI::CMD_PATH_SIG_MAP = Puma::ControlCLI::CMD_PATH_SIG_MAP.merge({ 'info' => 'SIGWINCH' }).freeze
  $VERBOSE = old_verbose
end

begin
  on_booted do
    AppVersion.start_maintenance_thread(process_name: 'puma')
    Zammad::ProcessDebug.install_thread_status_handler
  end
rescue NoMethodError
  # Workaround for https://github.com/puma/puma/issues/3356, can be removed after this is
  #   solved and a new puma version is released where 'pumactl status' works again.
end

if worker_count.positive?
  on_worker_boot do
    ActiveRecord::Base.establish_connection
    Zammad::ProcessDebug.install_thread_status_handler
  end
end
