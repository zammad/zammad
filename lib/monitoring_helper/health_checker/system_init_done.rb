# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module MonitoringHelper
  class HealthChecker
    class SystemInitDone < Backend

      def run_health_check
        return if Setting.get('system_init_done')

        response.issues.push 'The system setup is not completed.' # rubocop:disable Zammad/DetectTranslatableString
      end
    end
  end
end
