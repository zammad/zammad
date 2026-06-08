# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class BackgroundServices
  class Cli < ::Thor
    # rubocop:disable Zammad/DetectTranslatableString

    def self.exit_on_failure?
      # Signal to Thor API that failures should be reflected in the exit code.
      true
    end

    desc 'start', 'Execute background services.'
    def start
      config = BackgroundServices::ServiceConfig.configuration_from_env(ENV)
      if %w[1 true].include? ENV['BACKGROUND_SERVICES_LOG_TO_STDOUT']
        Zammad::Logging.extend_logging_to_stdout
      elsif Rails.env.development?
        puts 'BackgroundServices do not log to STDOUT. You can enable this by setting BACKGROUND_SERVICES_LOG_TO_STDOUT=1.' # rubocop:disable Rails/Output
      end

      BackgroundServices.new(config).run
    end

    def self.help(shell, subcommand = nil)
      super
      shell.say 'Startup behaviour can be customized with these environment variables:'
      shell.say

      list = [
        ['Service', 'Configuration', 'Variable', 'Default value'],
        ['-------', '-------------', '--------', '-------------'],
      ]
      BackgroundServices.available_services.each do |service|
        service_name = service.name.demodulize
        env_prefix   = "ZAMMAD_#{service_name.underscore.upcase}"
        list.push [service_name, 'worker count', "#{env_prefix}_WORKERS", "0 (= run in main process, max. #{service.max_workers})"]
        if service.max_worker_threads > 1
          list.push [nil, 'threads per worker', "#{env_prefix}_WORKER_THREADS", "#{service.default_worker_threads} (max. #{service.max_worker_threads})"]
        end
        list.push [nil, 'disable service', "#{env_prefix}_DISABLE"]
      end
      shell.print_table(list, indent: 2)

      shell.say
      shell.say 'For more information, please see https://docs.zammad.org/en/latest/appendix/configure-env-vars.html.'
    end

    # rubocop:enable Zammad/DetectTranslatableString
  end
end
