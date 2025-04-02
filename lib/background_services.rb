# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class BackgroundServices

  def self.available_services
    BackgroundServices::Service.descendants
  end

  CHILD_PROCESS_MONITOR_INTERVAL = 5.seconds
  # Waiting time before processes get killed.
  SHUTDOWN_GRACE_PERIOD = 30.seconds

  class_attribute :shutdown_requested

  attr_accessor :threads, :child_pids
  attr_reader   :config

  def initialize(config)
    @config = Array(config)
    @child_pids = []
    @threads    = []
    install_signal_trap
    AppVersion.start_maintenance_thread(process_name: 'background-worker')
    Zammad::ProcessDebug.install_thread_status_handler
  end

  def run
    Rails.logger.info 'Starting BackgroundServices...'

    # Fork before starting the threads in the main process to ensure a consistent state
    #   and minimal memory overhead (see also #5420).
    config
      .in_order_of(:start_as, %i[fork thread])
      .each do |service_config|
        run_service service_config
      end

    monitor_child_processes

    child_pids.each { |pid| Process.waitpid(pid) }
    threads.each(&:join)
  ensure
    Rails.logger.info('Stopping BackgroundServices.')
  end

  private

  # Check if child processes are still alive, terminate the main process otherwise to
  #   signal to the controlling process manager that the background worker needs a restart.
  def monitor_child_processes
    return if child_pids.blank?

    Thread.new do
      Thread.current.abort_on_exception = true
      Thread.current.name = 'child process monitoring'

      until self.class.shutdown_requested
        child_pids.each do |child_pid|
          Process.getpgid(child_pid)
        rescue Errno::ESRCH
          Rails.logger.error { "BackgroundServices child process #{child_pid} has died, terminating the background worker…" }
          Process.kill('TERM', Process.pid)
          Thread.current.exit
        end
        sleep CHILD_PROCESS_MONITOR_INTERVAL
      end
    end
  end

  def install_signal_trap
    Signal.trap('TERM') { handle_signal('TERM') }
    Signal.trap('INT')  { handle_signal('INT')  }
  end

  def handle_signal(signal)
    # Write operations cannot be handled in a signal handler, use a thread for that.
    #   This thread is not waited for via `join`, so that the main process should end
    #   somewhere during the sleep statement if it is able to shut down cleanly.
    #   If it doesn't, it will send KILL signals to all child processes and the main process
    #   to enforce the termination.
    Thread.new do
      Thread.current.name = 'shutdown handler'

      Rails.logger.info { "BackgroundServices shutdown requested via #{signal} signal for process #{Process.pid}" }

      sleep SHUTDOWN_GRACE_PERIOD

      Rails.logger.error { "BackgroundServices did not shutdown cleanly after #{SHUTDOWN_GRACE_PERIOD}s, forcing termination" }
      child_pids.each { |pid| Process.kill('KILL', pid) }
      Process.kill('KILL', Process.pid)
    end

    self.class.shutdown_requested = true
    child_pids.each do |pid|
      Process.kill(signal, pid)
    rescue Errno::ESRCH, RangeError
      # Don't fail if processes terminated already.
    end
  end

  def run_service(service_config)
    if !service_config.enabled?
      Rails.logger.info { "Skipping disabled service #{service_config.service.service_name}." }
      return
    end

    if service_config.service.skip?(manager: self)
      Rails.logger.info { "Skipping service #{service_config.service.service_name}." }
      return
    end

    service_config.service.pre_run

    case service_config.start_as
    when :fork
      child_pids.push(*start_as_forks(service_config.service, service_config.workers))
    when :thread
      threads.push start_as_thread(service_config.service)
    end
  end

  def start_as_forks(service, forks)
    (1..forks).map do |i|
      Process.fork do
        Process.setproctitle("#{$PROGRAM_NAME} #{service.service_name}##{i}")
        install_signal_trap
        Rails.logger.info { "Starting process ##{Process.pid} for service #{service.service_name}." }
        service.new(manager: self, fork_id: i).run
      rescue Interrupt
        nil
      end
    end
  end

  def start_as_thread(service)
    Thread.new do
      Thread.current.abort_on_exception = true
      Thread.current.name = "service #{service.service_name}"

      Rails.logger.info { "Starting thread for service #{service.service_name} in the main process." }
      service.new(manager: self).run
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
