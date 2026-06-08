# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Base class for background services
class BackgroundServices::Service
  include BackgroundServices::Concerns::HasInterruptibleSleep
  include Mixin::RequiredSubPaths

  attr_reader :fork_id, :manager, :service_config

  class << self

    def service_name
      name.demodulize
    end

    # Override this method in service classes that support more than one worker process.
    # The default worker count value is 0, which means that the service will run in the main process.
    def max_workers
      1
    end

    # Override this method in service classes that support more than one thread per worker.
    def max_worker_threads
      1
    end

    def default_worker_threads
      1
    end

    def skip?(manager:)
      false
    end

    # Use this method to prepare for a service task.
    # This would be called only once regardless of how many workers would start.
    def pre_run
      run_in_service_context do
        pre_launch
      end
    end

    def run_in_service_context(&)
      Rails.application.executor.wrap do
        ApplicationHandleInfo.use('scheduler', &)
      end
    end

    protected

    # Override this method in service classes that need to perform tasks once
    #   before threads/workers are started.
    def pre_launch; end
  end

  def initialize(manager:, fork_id: nil)
    @fork_id        = fork_id
    @manager        = manager

    return if !manager

    @service_config = manager.config.find { |elem| elem.service == self.class }
  end

  # Use this method to run a background service.
  def run
    multiple_threads? ? start_threads : run_single_thread
  end

  def start_threads
    threads_count.times.map do |i| # rubocop:disable Performance/TimesMap
      Thread.new do
        Thread.current.abort_on_exception = true
        Thread.current.name = "service #{self.class.name} thread ##{i}"

        run_single_thread
      rescue ActiveRecord::ActiveRecordError => e
        raise e if !BackgroundServices.tolerate_error?(e)
      end
    end.each(&:join)
  end

  def run_single_thread
    self.class.run_in_service_context do
      launch
    rescue => e
      # Intercept any exceptions, log them and rethrow to make sure they can be acted upon.
      Rails.logger.error { "#{self.class.name}#run() raised an error:" }
      Rails.logger.error { e }
      raise e
    end
  end

  protected

  def threads_count
    service_config&.worker_threads
  end

  def multiple_threads?
    threads_count && threads_count > 1
  end

  # Override this method in service classes.
  def launch; end
end
