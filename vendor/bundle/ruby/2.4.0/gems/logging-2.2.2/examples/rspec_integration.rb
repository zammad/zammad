# :stopdoc:
#
# One useful feature of log messages in your code is that they provide a
# convenient instrumentation point for testing. Through log messages you can
# confirm that internal methods were called or that certain code paths were
# executed. This example demonstrates how to capture log output during testing
# for later analysis.
#
# The Logging framework provides an RSpec helper that will direct log output
# to a StringIO appender. Log lines can be read from this IO destination
# during tests.
#

  require 'rspec'
  require 'logging'
  require 'rspec/logging_helper'

  # Configure RSpec to capture log messages for each test. The output from the
  # logs will be stored in the @log_output variable. It is a StringIO instance.
  RSpec.configure do |config|
    include RSpec::LoggingHelper
    config.capture_log_messages
  end

  # Now within your specs you can check that various log events were generated.
  describe 'SuperLogger' do
    it 'should be able to read a log message' do
      logger = Logging.logger['SuperLogger']

      logger.debug 'foo bar'
      logger.warn  'just a little warning'

      @log_output.readline.should be == 'DEBUG SuperLogger: foo bar'
      @log_output.readline.should be == 'WARN  SuperLogger: just a little warning'
    end
  end

# :startdoc:
