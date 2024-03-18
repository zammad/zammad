# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module MonitoringHelper
  class HealthChecker
    class FailedEmail < Backend

      def run_health_check
        count = ::FailedEmail.count

        return if count.zero?

        response.issues.push "emails that could not be processed: #{count}"
      end
    end
  end
end
