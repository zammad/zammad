# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'delayed/worker'

# Monkey patch for early exit during work_off, used by BackgroundServices::Service::ProcessDelayedJobs
module Delayed
  class Worker
    def stop?
      BackgroundServices.shutdown_requested
    end
  end
end
