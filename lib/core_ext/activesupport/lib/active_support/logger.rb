# This customization provides the possiblity to log exception backtraces via the Rails.logger.
#
# @example:
#  begin
#    instance = "String :)"
#    instance.invalid_method
#  rescue => e
#    Rails.logger.error e
#  end
#  #=> undefined method `invalid_method' for "String :)":String
#  #   ... backtrace ...
# https://github.com/rails/rails/blob/308e84e982b940983b4b3d5b41b0b3ac11fbae40/activesupport/lib/active_support/logger.rb#L101
module ActiveSupport
  class Logger < ::Logger
    class SimpleFormatter < ::Logger::Formatter
      # original behaviour:
      # rubocop:disable Lint/UnusedMethodArgument, Style/CaseEquality
      # This method is invoked when a log event occurs
      def call(severity, timestamp, progname, msg)
        return "#{String === msg ? msg : msg.inspect}\n" if !msg.is_a?(Exception)
        # rubocop:enable Lint/UnusedMethodArgument, Style/CaseEquality
        # custom -> print only the message if no backtrace is present
        return "#{msg.message}\n" if !msg.backtrace
        # otherwise combination of message and backtrace
        "#{msg.message}\n#{msg.backtrace.join("\n")}\n"
      end
    end
  end
end
