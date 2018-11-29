# Equivalent to a header guard in C/C++
# Used to prevent the class/module from being loaded more than once
unless defined? LOGGING_TEST_SETUP
LOGGING_TEST_SETUP = true

require "rubygems"
require "test/unit"

if Test::Unit::TestCase.respond_to? :test_order=
  Test::Unit::TestCase.test_order = :random
end

require File.expand_path("../../lib/logging", __FILE__)

module TestLogging
  module LoggingTestCase

    TMP = 'tmp'

    def setup
      super
      Logging.reset
      FileUtils.rm_rf TMP
      FileUtils.mkdir TMP
    end

    def teardown
      super
      FileUtils.rm_rf TMP
    end
  end
end

end
