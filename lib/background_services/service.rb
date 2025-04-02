# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

# Base class for background services
class BackgroundServices::Service
  include BackgroundServices::Concerns::HasInterruptibleSleep
  include Mixin::RequiredSubPaths

  attr_reader :fork_id, :manager

  def self.service_name
    name.demodulize
  end

  # Override this method in service classes that support more than one worker process.
  def self.max_workers
    1
  end

  def self.skip?(manager:)
    false
  end

  # Use this method to prepare for a service task.
  # This would be called only once regardless of how many workers would start.
  def self.pre_run
    run_in_service_context do
      pre_launch
    end
  end

  def self.run_in_service_context(&)
    Rails.application.executor.wrap do
      ApplicationHandleInfo.use('scheduler', &)
    end
  end

  def initialize(manager:, fork_id: nil)
    @fork_id = fork_id
    @manager = manager
  end

  # Use this method to run a background service.
  def run
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

  # Override this method in service classes.
  def launch; end

  class << self
    protected

    # Override this method in service classes that need to perform tasks once
    #   before threads/workers are started.
    def pre_launch; end
  end
end
