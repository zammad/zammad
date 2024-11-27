# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class BackgroundServices

  def self.available_services
    BackgroundServices::Service.descendants
  end

  attr_reader :config

  def initialize(config)
    @config = Array(config)
  end

  def run
    Rails.logger.debug 'Starting BackgroundServices...'

    config.each do |service_config|
      run_service service_config
    end

    Process.waitall

    loop do
      sleep 1
    end
  rescue Interrupt
    nil
  ensure
    Rails.logger.debug('Stopping BackgroundServices.')
  end

  private

  def run_service(service_config)
    if !service_config.enabled?
      Rails.logger.debug { "Skipping disabled service #{service_config.service.service_name}." }
      return
    end

    service_config.service.pre_run

    case service_config.start_as
    when :fork
      start_as_forks(service_config.service, service_config.workers)
    when :thread
      start_as_thread(service_config.service)
    end
  end

  def start_as_forks(service, forks)
    (1..forks).map do
      Process.fork do
        Rails.logger.debug { "Starting process ##{Process.pid} for service #{service.service_name}." }
        service.new.run
      rescue Interrupt
        nil
      end
    end
  end

  def start_as_thread(service)
    Thread.new do
      Thread.current.abort_on_exception = true

      Rails.logger.debug { "Starting thread for service #{service.service_name} in the main process." }
      service.new.run
    # BackgroundServices rspec test is using Timeout.timeout to stop background services.
    # It was fine for a long time, but started throwing following error in Rails 7.2.
    # This seems to affect that test case only.
    # Unfortunately, since it's running on a separate thread, that error has to be rescued here.
    # That said, this should be handled by improving services loops to support graceful exiting.
    rescue ActiveRecord::ActiveRecordError => e
      raise e if Rails.env.test? && e.message != 'Cannot expire connection, it is not currently leased.' # rubocop:disable Zammad/DetectTranslatableString
    end
  end
end
