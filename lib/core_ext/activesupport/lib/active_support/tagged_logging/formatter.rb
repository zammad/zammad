# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

# This customization removes the tagged logging functionality in favour of logging exception backtraces via the Rails.logger.
# Zammad uses Logger::Formatter which partly provides the functionality to log exceptions if given.
# ActiveSupport::TaggedLogging::Formatter removes this by addind the tags as a string which converts the Exception class to
# a flat string without the backtrace and other information. It's reduced to only the exception text. This is not wanted
# in our context.
# ActiveSupport::TaggedLogging::Formatter addresses:
# subdomains, request ids, and anything else to aid debugging of multi-user production applications.
# Which is not needed for us
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
# https://github.com/rails/rails/blob/89fab56597c335bb49887563b9a98386b5171574/activesupport/lib/active_support/tagged_logging.rb
module ActiveSupport
  module TaggedLogging
    module Formatter
      # This method is invoked when a log event occurs.
      def call(severity, timestamp, progname, msg) # rubocop:disable Lint/UselessMethodDefinition
        # super(severity, timestamp, progname, "#{tags_text}#{msg}")
        super(severity, timestamp, progname, msg)
      end
    end
  end
end
