# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class BackgroundServices::Service::ProcessScheduledJobs
  class JobExecutor::OneTime < JobExecutor
    def run
      execute
    end
  end
end
