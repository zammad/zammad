# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module MonitoringHelper
  class HealthChecker
    class S3StorageAvailability < Backend

      def run_health_check
        return if Setting.get('storage_provider') != 'S3'

        return if Store::Provider::S3.ping?

        response.issues.push __('The Simple Storage Service is not available.')
      end
    end
  end
end
