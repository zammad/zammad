# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class BackgroundServices::Service::ProcessScheduledJobs
  class JobExecutor::OneTime < JobExecutor
    def run
      return if BackgroundServices.shutdown_requested

      execute
    end
  end
end
