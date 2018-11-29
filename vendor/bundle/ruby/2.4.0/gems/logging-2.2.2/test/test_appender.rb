
require File.expand_path('setup', File.dirname(__FILE__))

module TestLogging

  class TestAppender < Test::Unit::TestCase
    include LoggingTestCase

    def setup
      super

      ::Logging.init
      @levels = ::Logging::LEVELS
      @event = ::Logging::LogEvent.new('logger', @levels['debug'],
                                       'message', false)
      @appender = ::Logging::Appender.new 'test_appender'
    end

    def test_append
      ary = []
      @appender.instance_variable_set :@ary, ary
      def @appender.write( event )
        str = event.instance_of?(::Logging::LogEvent) ?
              @layout.format(event) : event.to_s
        @ary << str
      end

      assert_nothing_raised {@appender.append @event}
      assert_equal "DEBUG  logger : message\n", ary.pop

      @appender.level = :info
      @appender.append @event
      assert_nil ary.pop

      @event.level = @levels['info']
      @appender.append @event
      assert_equal " INFO  logger : message\n", ary.pop

      @appender.close
      assert_raise(RuntimeError) {@appender.append @event}
    end

    def test_append_with_filter
      ary = []
      @appender.instance_variable_set :@ary, ary
      def @appender.write(event)
        @ary << event
      end
      @appender.level = :debug

      # Excluded
      @appender.filters = ::Logging::Filters::Level.new :info
      @appender.append @event
      assert_nil ary.pop

      # Allowed
      @appender.filters = ::Logging::Filters::Level.new :debug
      @appender.append @event
      assert_equal @event, ary.pop

      # No filter
      @appender.filters = nil
      @appender.append @event
      assert_equal @event, ary.pop
    end

    def test_append_with_modifying_filter
      ary = []
      @appender.instance_variable_set :@ary, ary
      def @appender.write(event)
        @ary << event
      end
      @appender.level = :debug
      @appender.filters = [
        ::Logging::Filters::Level.new(:debug, :info),
        RedactFilter.new
      ]

      # data will be redacted
      @appender.append @event
      event = ary.pop
      assert_not_same @event, event
      assert_equal "REDACTED!", event.data

      # event will be filtered out
      @event.level = @levels['warn']
      @appender.append @event
      assert_nil ary.pop
    end

    def test_close
      assert_equal false, @appender.closed?

      @appender.close
      assert_equal true, @appender.closed?
    end

    def test_closed_eh
      assert_equal false, @appender.closed?

      @appender.close
      assert_equal true, @appender.closed?
    end

    def test_concat
      ary = []
      @appender.instance_variable_set :@ary, ary
      def @appender.write( event )
        str = event.instance_of?(::Logging::LogEvent) ?
              @layout.format(event) : event.to_s
        @ary << str
      end

      assert_nothing_raised {@appender << 'log message'}
      assert_equal 'log message', ary.pop

      @appender.level = :off
      @appender << 'another log message'
      assert_nil ary.pop

      layout = @appender.layout
      def layout.footer() 'this is the footer' end

      @appender.close
      assert_raise(RuntimeError)  {@appender << 'log message'}
      assert_equal 'this is the footer', ary.pop
    end

    def test_flush
      assert_same @appender, @appender.flush
    end

    def test_initialize
      assert_raise(TypeError) {::Logging::Appender.new 'test', :layout => []}

      layout = ::Logging::Layouts::Basic.new
      @appender = ::Logging::Appender.new 'test', :layout => layout
      assert_same layout, @appender.instance_variable_get(:@layout)
    end

    def test_layout
      assert_instance_of ::Logging::Layouts::Basic, @appender.layout
    end

    def test_layout_eq
      layout = ::Logging::Layouts::Basic.new
      assert_not_equal layout, @appender.layout

      assert_raise(TypeError) {@appender.layout = Object.new}
      assert_raise(TypeError) {@appender.layout = 'not a layout'}

      @appender.layout = layout
      assert_same layout, @appender.layout
    end

    def test_level
      assert_equal 0, @appender.level
    end

    def test_level_eq
      assert_equal 0, @appender.level

      assert_raise(ArgumentError) {@appender.level = -1}
      assert_raise(ArgumentError) {@appender.level =  6}
      assert_raise(ArgumentError) {@appender.level = Object}
      assert_raise(ArgumentError) {@appender.level = 'bob'}
      assert_raise(ArgumentError) {@appender.level = :wtf}

      @appender.level = 'INFO'
      assert_equal 1, @appender.level

      @appender.level = :warn
      assert_equal 2, @appender.level

      @appender.level = 'error'
      assert_equal 3, @appender.level

      @appender.level = 4
      assert_equal 4, @appender.level

      @appender.level = 'off'
      assert_equal 5, @appender.level

      @appender.level = :all
      assert_equal 0, @appender.level
    end

    def test_name
      assert_equal 'test_appender', @appender.name
    end

    def test_to_s
      assert_equal "<Appender name=\"test_appender\">", @appender.to_s
    end
  end  # class TestAppender
end  # module TestLogging

class RedactFilter < ::Logging::Filter
  def allow( event )
    event = event.dup
    event.data = "REDACTED!"
    event
  end
end

