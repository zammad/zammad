# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class BackgroundServices
  class ServiceConfig
    attr_reader :service, :disabled

    def self.configuration_from_env(input)
      BackgroundServices
        .available_services
        .map { |service| single_configuration_from_env(service, input) }
    end

    def self.single_configuration_from_env(service, input)
      env_prefix = "ZAMMAD_#{service.service_name.underscore.upcase}"

      new(
        service:  service,
        disabled: ActiveModel::Type::Boolean.new.cast(input["#{env_prefix}_DISABLED"]) || false,
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
