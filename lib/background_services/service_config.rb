# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class BackgroundServices
  class ServiceConfig
    attr_reader :service, :disabled

    def self.configuration_from_env(input)

      if !input['ZAMMAD_PROCESS_SESSIONS_JOBS_WORKERS'] && input['ZAMMAD_SESSION_JOBS_CONCURRENT']
        input['ZAMMAD_PROCESS_SESSIONS_JOBS_WORKERS'] = input['ZAMMAD_SESSION_JOBS_CONCURRENT']

        ActiveSupport::Deprecation.send(:warn, 'The environment variable ZAMMAD_SESSION_JOBS_CONCURRENT is deprecated, please use ZAMMAD_PROCESS_SESSIONS_JOBS_WORKERS instead.') # rubocop:disable Zammad/DetectTranslatableString
      end

      BackgroundServices
        .available_services
        .map { |service| single_configuration_from_env(service, input) }
    end

    def self.single_configuration_from_env(service, input)
      env_prefix = "ZAMMAD_#{service.service_name.underscore.upcase}"

      new(
        service:  service,
        disabled: ActiveModel::Type::Boolean.new.cast(input["#{env_prefix}_DISABLE"]) || false,
        workers:  input["#{env_prefix}_WORKERS"].to_i,
      )
    end

    def initialize(service:, disabled:, workers:)
      @service  = service
      @disabled = disabled
      @workers  = workers
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
  end
end
