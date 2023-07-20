# Copyright (C) 2023-2023 Intevation GmbH, https://intevation.de/

module MonitoringHelper
  class HealthChecker
    class OversizedMail < Backend

      def run_health_check
        return if !File.exist?(Channel::EmailParser::OVERSIZED_MAIL_DIRECTORY)

        count = Dir.glob("#{Channel::EmailParser::OVERSIZED_MAIL_DIRECTORY}/*.eml").count

        return if count.zero?

        response.issues.push "oversized mails: #{count}"
      end
    end
  end
end
