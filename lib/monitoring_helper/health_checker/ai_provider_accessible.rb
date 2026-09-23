# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module MonitoringHelper
  class HealthChecker
    # Reports every assigned AI provider connection whose last real call failed, based on the
    # stored health status (channel-style: reads only, does not ping). An unassigned connection
    # serves nothing and gets no call that could clear its error, so it is left out.
    class AIProviderAccessible < Backend

      def run_health_check
        return if !Setting.get('ai_provider')

        if AI::ProviderConnection.none?
          response.issues.push 'The AI provider is not configured.' # rubocop:disable Zammad/DetectTranslatableString
          return
        end

        AI::ProviderConnection.in_use.select(&:status_error?).each { |connection| report_issue(connection) }
      end

      private

      def report_issue(connection)
        message = "The AI provider connection '#{connection.name}' is not accessible."

        status = connection.status
        message += " #{status['message']}" if status['message'].present?
        message += " (#{status['at']})" if status['at'].present?

        response.issues.push message
      end
    end
  end
end
