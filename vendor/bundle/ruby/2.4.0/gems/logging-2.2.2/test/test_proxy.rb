
require File.expand_path('../setup', __FILE__)

module TestLogging

  class TestProxy < Test::Unit::TestCase
    include LoggingTestCase

    def setup
      super

      ::Logging.init
      @appender = Logging.appenders.string_io('test_appender')
      logger = Logging.logger[Array]
      logger.level = :debug
      logger.appenders = @appender
    end

    def test_initialize
      ary = []
      proxy = Logging::Proxy.new ary

      assert_instance_of Array, proxy

      proxy.concat [1,2,3]
      assert_equal 3, proxy.length
      assert_equal [1,2,3], ary
    end

    def test_method_logging
      proxy = Logging::Proxy.new []
      assert_equal 0, proxy.length
      assert_equal "Array#length()\n", @appender.readline

      proxy.concat [1,2,3]
      assert_equal "Array#concat(#{[1,2,3].inspect})\n", @appender.readline

      proxy = Logging::Proxy.new Array
      proxy.name
      assert_equal "Array.name()\n", @appender.readline

      proxy.new 0
      assert_equal "Array.new(0)\n", @appender.readline
    end

    def test_custom_method_logging
      proxy = Logging::Proxy.new([]) { |name, *args, &block|
        @logger << "#@leader#{name}(#{args.inspect[1..-2]})"
        rv = @object.__send__(name, *args, &block)
        @logger << " => #{rv.inspect}\n"
        rv
      }
      @appender.clear

      assert_equal 0, proxy.length
      assert_equal "Array#length() => 0\n", @appender.readline

      proxy.concat [1,2,3]
      assert_equal "Array#concat(#{[1,2,3].inspect}) => #{[1,2,3].inspect}\n", @appender.readline

      proxy.concat [4,5,6]
      assert_equal "Array#concat(#{[4,5,6].inspect}) => #{[1,2,3,4,5,6].inspect}\n", @appender.readline
    end

    def test_error_when_proxying_nil
      assert_raises(ArgumentError, 'Cannot proxy nil') {
        Logging::Proxy.new nil
      }
    end

  end  # TestProxy
end  # TestLogging

