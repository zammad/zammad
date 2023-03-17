# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

# Base class for background services
class BackgroundServices::Service
  include Mixin::RequiredSubPaths

  def self.service_name
    name.demodulize
  end

  # Override this method in service classes that support more than one worker process.
  def self.max_workers
    1
  end

  # Use this method to prepare for a service task.
  # This would be called only once regardless of how many workers would start.
  def self.pre_run
    run_in_service_context do
      pre_launch
    end
  end

  # Use this method to run a background service.
  def run
    self.class.run_in_service_context do
      launch
    end
  end

  def self.run_in_service_context(&)
    Rails.application.executor.wrap do
      ApplicationHandleInfo.use('scheduler', &)
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
