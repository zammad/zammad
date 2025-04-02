# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class SystemReport::Plugin::Environment < SystemReport::Plugin
  DESCRIPTION = __('Configuration of performance settings via environment variables.').freeze

  def fetch
    {
      'RAILS_LOG_TO_STDOUT'                   => ENV['RAILS_LOG_TO_STDOUT'].present?,
      'ZAMMAD_SAFE_MODE'                      => ENV['ZAMMAD_SAFE_MODE'].present?,
      'ZAMMAD_RAILS_PORT'                     => ENV['ZAMMAD_RAILS_PORT'].present?,
      'ZAMMAD_WEBSOCKET_PORT'                 => ENV['ZAMMAD_WEBSOCKET_PORT'].present?,
      'WEB_CONCURRENCY'                       => ENV['WEB_CONCURRENCY'],
      'ZAMMAD_PROCESS_SESSIONS_JOBS_WORKERS'  => ENV['ZAMMAD_PROCESS_SESSIONS_JOBS_WORKERS'],
      'ZAMMAD_PROCESS_SCHEDULED_JOBS_WORKERS' => ENV['ZAMMAD_PROCESS_SCHEDULED_JOBS_WORKERS'],
      'ZAMMAD_PROCESS_DELAYED_JOBS_WORKERS'   => ENV['ZAMMAD_PROCESS_DELAYED_JOBS_WORKERS'],
      # deprecated settings
      'ZAMMAD_SESSION_JOBS_CONCURRENT'        => ENV['ZAMMAD_SESSION_JOBS_CONCURRENT'],
    }
  end
end
