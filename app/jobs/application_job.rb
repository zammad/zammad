# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class ApplicationJob < ActiveJob::Base
  include ApplicationJob::HasDelayedJobMonitoringCompatibilty
  include ApplicationJob::HasQueuingPriority
  include ApplicationJob::HasCustomLogging

  # Automatically retry jobs that encountered a deadlock
  # retry_on ActiveRecord::Deadlocked

  # Most jobs are safe to ignore if the underlying records are no longer available
  # discard_on ActiveJob::DeserializationError
end
