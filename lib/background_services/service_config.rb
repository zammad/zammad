# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class BackgroundServices
  class ServiceConfig
    attr_reader :service, :disabled

    def self.configuration_from_env(input)

      if !input['ZAMMAD_PROCESS_SESSIONS_JOBS_WORKERS'] && input['ZAMMAD_SESSION_JOBS_CONCURRENT']
        input['ZAMMAD_PROCESS_SESSIONS_JOBS_WORKERS'] = input['ZAMMAD_SESSION_JOBS_CONCURRENT']

        ActiveSupport::Deprecation.new.warn('The environment variable ZAMMAD_SESSION_JOBS_CONCURRENT is deprecated, please use ZAMMAD_PROCESS_SESSIONS_JOBS_WORKERS instead.')
        Rails.logger.warn('The environment variable ZAMMAD_SESSION_JOBS_CONCURRENT is deprecated, please use ZAMMAD_PROCESS_SESSIONS_JOBS_WORKERS instead.')
      end

      BackgroundServices
        .available_services
        .map { |service| single_configuration_from_env(service, input) }
    end

    def self.single_configuration_from_env(service, input)
      env_prefix = "ZAMMAD_#{service.service_name.underscore.upcase}"

      new(
        service:        service,
        disabled:       ActiveModel::Type::Boolean.new.cast(input["#{env_prefix}_DISABLE"]) || false,
        workers:        input["#{env_prefix}_WORKERS"].to_i,
        worker_threads: (input["#{env_prefix}_WORKER_THREADS"].presence || service.default_worker_threads).to_i,
      )
    end

    def initialize(service:, disabled:, workers:, worker_threads:)
      @service  = service
      @disabled = disabled
      @workers  = workers
      @worker_threads = worker_threads
    end

    def enabled?
      !disabled
    end

    def start_as
      if workers.positive?
        :fork
      else
        :thread
      end
    end

    def workers
      [@workers, service.max_workers].min
    end

    def worker_threads
      [@worker_threads, service.max_worker_threads].min
    end
  end
end
