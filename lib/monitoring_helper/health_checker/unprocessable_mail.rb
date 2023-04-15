# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module MonitoringHelper
  class HealthChecker
    class UnprocessableMail < Backend

      def run_health_check
        return if !File.exist?(Channel::EmailParser::UNPROCESSABLE_MAIL_DIRECTORY)

        count = Dir.glob("#{Channel::EmailParser::UNPROCESSABLE_MAIL_DIRECTORY}/*.eml").count

        return if count.zero?

        response.issues.push "unprocessable mails: #{count}"
      end
    end
  end
end
