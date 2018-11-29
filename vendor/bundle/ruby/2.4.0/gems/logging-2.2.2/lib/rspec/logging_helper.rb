
module RSpec
  module LoggingHelper

    # Capture log messages from the Logging framework and make them
    # available via a @log_output instance variable. The @log_output
    # supports a readline method to access the log messages.
    #
    def capture_log_messages( opts = {} )
      from = opts.fetch(:from, 'root')
      to = opts.fetch(:to, '__rspec__')
      exclusive = opts.fetch(:exclusive, true)

      appender = Logging::Appenders[to] || Logging::Appenders::StringIo.new(to)
      logger = Logging::Logger[from]
      if exclusive
        logger.appenders = appender
      else
        logger.add_appenders(appender)
      end

      before(:all) do
        @log_output = Logging::Appenders[to]
      end

      before(:each) do
        @log_output.reset
      end
    end

  end  # module LoggingHelper
end  # module RSpec

if defined?  RSpec::Core::Configuration
  class RSpec::Core::Configuration
    include RSpec::LoggingHelper
  end
end

