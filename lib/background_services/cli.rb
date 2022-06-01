# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class BackgroundServices
  class Cli < ::Thor
    # rubocop:disable Zammad/DetectTranslatableString

    def self.exit_on_failure?
      # Signal to Thor API that failures should be reflected in the exit code.
      true
    end

    desc 'start', 'Execute background services.'
    def start
      lock
      config = BackgroundServices::ServiceConfig.configuration_from_env(ENV)
      BackgroundServices.new(config).run
    ensure
      release_lock
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

    private

    def lock
      @lock_file = File.open(__FILE__, 'r')
      return if @lock_file.flock(File::LOCK_EX | File::LOCK_NB)

      raise 'Cannot start BackgroundServices, another process seems to be running.'
    end

    def release_lock
      @lock_file.close
    end

    # rubocop:enable Zammad/DetectTranslatableString
  end
end
