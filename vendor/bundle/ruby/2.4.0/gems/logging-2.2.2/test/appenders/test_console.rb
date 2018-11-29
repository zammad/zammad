
require File.expand_path('../setup', File.dirname(__FILE__))

module TestLogging
module TestAppenders

  class TestConsole < Test::Unit::TestCase
    include LoggingTestCase

    def test_initialize
      assert_raise(RuntimeError) { Logging::Appenders::Console.new("test") }
    end
  end

  class TestStdout < Test::Unit::TestCase
    include LoggingTestCase

    def test_initialize
      Logging::Repository.instance

      appender = Logging.appenders.stdout
      assert_equal 'stdout', appender.name
      assert_same STDOUT, appender.instance_variable_get(:@io)

      appender.close
      assert_equal true, appender.closed?
      assert_equal false, STDOUT.closed?

      appender = Logging.appenders.stdout('foo')
      assert_equal 'foo', appender.name

      appender = Logging.appenders.stdout(:level => :warn)
      assert_equal 'stdout', appender.name
      assert_equal 2, appender.level

      appender = Logging.appenders.stdout('bar', :level => :error)
      assert_equal 'bar', appender.name
      assert_equal 3, appender.level
    end

  end  # class TestStdout

  class TestStderr < Test::Unit::TestCase
    include LoggingTestCase

    def test_initialize
      Logging::Repository.instance

      appender = Logging.appenders.stderr
      assert_equal 'stderr', appender.name
      assert_same STDERR, appender.instance_variable_get(:@io)

      appender.close
      assert_equal true, appender.closed?
      assert_equal false, STDERR.closed?

      appender = Logging.appenders.stderr('foo')
      assert_equal 'foo', appender.name

      appender = Logging.appenders.stderr(:level => :warn)
      assert_equal 'stderr', appender.name
      assert_equal 2, appender.level

      appender = Logging.appenders.stderr('bar', :level => :error)
      assert_equal 'bar', appender.name
      assert_equal 3, appender.level
    end

  end  # class TestStderr

end  # module TestAppenders
end  # module TestLogging

