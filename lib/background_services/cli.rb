# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

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
      BackgroundServices.new(config).run
    end

    def self.help(shell, subcommand = nil)
      super
      shell.say 'Startup behaviour can be customized with these environment variables:'
      shell.say

      list = [
        ['Service', 'Set worker count', 'Max. workers', 'Disable this service'],
        ['-------', '----------------', '------------', '--------------------'],
      ]
      BackgroundServices.available_services.each do |service|
        service_name = service.name.demodulize
        env_prefix   = "ZAMMAD_#{service_name.underscore.upcase}"
        list.push [service_name, "#{env_prefix}_WORKERS", service.max_workers, "#{env_prefix}_DISABLE"]
      end
      shell.print_table(list, indent: 2)

      shell.say
      shell.say 'For more information, please see https://docs.zammad.org/en/latest/appendix/configure-env-vars.html.'
    end

    # rubocop:enable Zammad/DetectTranslatableString
  end
end
