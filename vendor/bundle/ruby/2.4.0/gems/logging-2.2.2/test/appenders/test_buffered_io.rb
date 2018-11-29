# encoding: UTF-8

require File.expand_path('../setup', File.dirname(__FILE__))

module TestLogging
module TestAppenders

  class TestBufferedIO < Test::Unit::TestCase
    include LoggingTestCase

    def setup
      super
      @appender = Logging.appenders.string_io \
        'test_appender',
        :auto_flushing => 3,
        :immediate_at  => :error,
        :encoding      => 'UTF-8'

      @appender.clear
      @sio = @appender.sio
      @levels = Logging::LEVELS
      begin readline rescue EOFError end
    end

    def test_append
      event = Logging::LogEvent.new('TestLogger', @levels['warn'],
                                    [1, 2, 3, 4], false)
      @appender.append event
      assert_nil(readline)

      @appender.append event
      assert_nil(readline)

      event.level = @levels['debug']
      event.data = 'the big log message'
      @appender.append event

      assert_equal " WARN  TestLogger : <Array> #{[1, 2, 3, 4]}\n", readline
      assert_equal " WARN  TestLogger : <Array> #{[1, 2, 3, 4]}\n", readline
      assert_equal "DEBUG  TestLogger : the big log message\n", readline
      assert_nil(readline)

      @appender.close
      assert_raise(RuntimeError) {@appender.append event}
    end

    def test_append_with_write_size
      event = Logging::LogEvent.new('TestLogger', @levels['warn'], %w[a b c d], false)
      @appender.write_size = 2

      @appender.append event
      assert_nil(readline)

      @appender.append event
      assert_nil(readline)

      event.level = @levels['debug']
      event.data = 'the big log message'
      @appender.append event

      assert_equal " WARN  TestLogger : <Array> #{%w[a b c d]}\n", readline
      assert_equal " WARN  TestLogger : <Array> #{%w[a b c d]}\n", readline
      assert_equal "DEBUG  TestLogger : the big log message\n", readline
      assert_nil(readline)
    end

    def test_append_error
      # setup an internal logger to capture error messages from the IO
      # appender
      log = Logging.appenders.string_io('__internal_io')
      Logging.logger[Logging].add_appenders(log)
      Logging.logger[Logging].level = 'all'


      # close the string IO object so we get an error
      @sio.close
      event = Logging::LogEvent.new('TestLogger', @levels['warn'],
                                    [1, 2, 3, 4], false)
      @appender.append event
      assert_nil(log.readline)

      @appender.append event
      assert_nil(log.readline)

      @appender.append event
      assert_equal "INFO  Logging : appender \"test_appender\" has been disabled", log.readline.strip
      assert_equal "ERROR  Logging : <IOError> not opened for writing", log.readline.strip

      assert_equal false, @appender.closed?
      assert_equal 5, @appender.level
    end

    def test_auto_flushing
      assert_raise(ArgumentError) {
        @appender.auto_flushing = Object.new
      }

      assert_raise(ArgumentError) {
        @appender.auto_flushing = -1
      }

      @appender.auto_flushing = 0
      assert_equal Logging::Appenders::Buffering::DEFAULT_BUFFER_SIZE, @appender.auto_flushing
    end

    def test_close
      assert_equal false, @sio.closed?
      assert_equal false, @appender.closed?

      @appender.close
      assert_equal true, @sio.closed?
      assert_equal true, @appender.closed?

      [STDIN, STDERR, STDOUT].each do |io|
        @appender = Logging.appenders.io('test', io)
        @appender.close
        assert_equal false, io.closed?
        assert_equal true, @appender.closed?
      end
    end

    def test_concat
      @appender << "this is a test message\n"
      assert_nil(readline)

      @appender << "this is another message\n"
      assert_nil(readline)

      @appender << "some other line\n"

      assert_equal "this is a test message\n", readline
      assert_equal "this is another message\n", readline
      assert_equal "some other line\n", readline
      assert_nil(readline)

      @appender.close
      assert_raise(RuntimeError) {@appender << 'message'}
    end

    def test_concat_error
      # setup an internal logger to capture error messages from the IO
      # appender
      log = Logging.appenders.string_io('__internal_io')
      Logging.logger[Logging].add_appenders(log)
      Logging.logger[Logging].level = 'all'

      # close the string IO object so we get an error
      @sio.close
      @appender << 'oopsy'
      assert_nil(log.readline)

      @appender << 'whoopsy'
      assert_nil(log.readline)

      @appender << 'pooh'
      assert_equal "INFO  Logging : appender \"test_appender\" has been disabled", log.readline.strip
      assert_equal "ERROR  Logging : <IOError> not opened for writing", log.readline.strip

      # and the appender does not close itself
      assert_equal false, @appender.closed?
      assert_equal 5, @appender.level
    end

    def test_flush
      @appender << "this is a test message\n"
      assert_nil(readline)

      @appender.flush
      assert_equal "this is a test message\n", readline
      assert_nil(readline)
    end

    def test_clear
      @appender << "this is a test message\n"
      @appender << "this is another test message\n"

      @appender.clear!
      @appender.flush
      assert_nil(readline)
    end

    def test_immediate_at
      event = Logging::LogEvent.new('TestLogger', @levels['warn'],
                                    [1, 2, 3, 4], false)
      @appender.append event
      assert_nil(readline)

      event.level = @levels['error']
      event.data = 'an error message'
      @appender.append event

      assert_equal " WARN  TestLogger : <Array> #{[1, 2, 3, 4]}\n", readline
      assert_equal "ERROR  TestLogger : an error message\n", readline
      assert_nil(readline)
    end

    if Object.const_defined?(:Encoding)
      def test_force_encoding
        a = 'ümlaut'
        b = 'hello ümlaut'.force_encoding('BINARY')

        event_a = Logging::LogEvent.new('TestLogger', @levels['info'], a, false)
        event_b = Logging::LogEvent.new('TestLogger', @levels['info'], b, false)

        @appender.append event_a
        @appender.append event_b
        assert_nil(readline)

        @appender.append event_a
        assert_equal " INFO  TestLogger : #{a}\n", readline
        assert_equal " INFO  TestLogger : #{b.force_encoding('UTF-8')}\n", readline
        assert_equal " INFO  TestLogger : #{a}\n", readline
        assert_nil(readline)
      end
    end

  private
    def readline
      @appender.readline
    end

  end  # class TestBufferedIO

end  # module TestAppenders
end  # module TestLogging

