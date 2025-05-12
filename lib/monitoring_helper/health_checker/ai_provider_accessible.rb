# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module MonitoringHelper
  class HealthChecker
    class AIProviderAccessible < Backend

      def run_health_check
        provider = Setting.get('ai_provider')
        return if provider.blank?

        provider_config = Setting.get('ai_provider_config')
        return if provider_config.blank?

        begin
          AI::Provider.by_name(provider).ping!(provider_config)
        rescue AI::Provider::ResponseError
          response.issues.push __('The AI Provider is not accessible.')
        end
      end
    end
  end
end
