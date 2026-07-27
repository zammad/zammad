# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module MonitoringHelper
  class HealthChecker
    class AIProviderAccessible < Backend

      def run_health_check
        return if !Setting.get('ai_provider')

        provider_config = Setting.get('ai_provider_config')
        provider = AI::Provider.by_config(provider_config)

        if provider.nil?
          response.issues.push 'The AI provider is not configured.' # rubocop:disable Zammad/DetectTranslatableString
          return
        end

        begin
          provider.ping!(provider_config)
        rescue AI::Provider::ResponseError
          response.issues.push 'The AI Provider is not accessible.' # rubocop:disable Zammad/DetectTranslatableString
        end
      end
    end
  end
end
