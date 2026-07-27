# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module MonitoringHelper
  class HealthChecker
    class ImportMode < Backend

      def run_health_check
        return if !Setting.get('import_mode')

        response.issues.push 'The instance is running in import_mode - please check the configuration if this is not intended.' # rubocop:disable Zammad/DetectTranslatableString
      end
    end
  end
end
