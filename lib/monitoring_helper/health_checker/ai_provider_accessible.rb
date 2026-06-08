# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module MonitoringHelper
  class HealthChecker
    class AIProviderAccessible < Backend

      def run_health_check
        return if !Setting.get('ai_provider')

        provider_config = Setting.get('ai_provider_config')
        provider = AI::Provider.by_config(provider_config)

        if provider.nil?
          response.issues.push __('The AI provider is not configured.')
          return
        end

        begin
          provider.ping!(provider_config)
        rescue AI::Provider::ResponseError
          response.issues.push __('The AI Provider is not accessible.')
        end
      end
    end
  end
end
