# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module MonitoringHelper
  class HealthChecker
    class UnprocessableMail < Backend
      DIRECTORY = Rails.root.join('tmp/unprocessable_mail')

      def run_health_check
        return if !File.exist?(DIRECTORY)

        count = Dir.glob("#{DIRECTORY}/*.eml").count

        return if count.zero?

        response.issues.push "unprocessable mails: #{count}"
      end
    end
  end
end
