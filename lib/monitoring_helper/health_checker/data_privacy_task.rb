# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module MonitoringHelper
  class HealthChecker
    class DataPrivacyTask < Backend
      TIMEOUT = 30.minutes

      def run_health_check
        scope.find_each do |task|
          response.issues.push "Stuck data privacy task (ID #{task.id}) detected. Last update: #{task.updated_at}"
        end
      end

      private

      def scope
        ::DataPrivacyTask
          .where.not(state: 'completed')
          .where('updated_at <= ?', TIMEOUT.ago)
      end
    end
  end
end
