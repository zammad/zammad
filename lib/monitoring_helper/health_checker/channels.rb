# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module MonitoringHelper
  class HealthChecker
    class Channels < Backend
      include ActionView::Helpers::DateHelper

      LAST_RUN_TOLERANCE = 1.hour
      OPTIONS_KEYS       = %w[host user uid].freeze

      def run_health_check
        scope.each { |channel| single_channel_check(channel) }
      end

      private

      def scope
        Channel.where(active: true)
      end

      def single_channel_check(channel)
        status_in(channel)
        status_out(channel)
        last_fetch(channel)
      end

      def status_in(channel)
        return if channel.status_in != 'error'

        message = status_message(channel, :in)

        response.issues.push "#{message} #{channel.last_log_in}"
      end

      def status_out(channel)
        return if channel.status_out != 'error'

        message = status_message(channel, :out)

        response.issues.push "#{message} #{channel.last_log_out}"
      end

      def status_message(channel, direction)
        message = "Channel: #{channel.area} #{direction} "

        OPTIONS_KEYS.each do |key|
          next if channel.options[key].blank?

          message += "#{key}:#{channel.options[key]};"
        end

        message
      end

      def last_fetch(channel)
        last_fetch = channel.preferences&.dig('last_fetch')

        return if !last_fetch
        return if last_fetch >= LAST_RUN_TOLERANCE.ago

        message = status_message(channel, :in)

        response.issues.push "#{message} is active but not fetched for #{time_ago_in_words(last_fetch)}"
      end
    end
  end
end
