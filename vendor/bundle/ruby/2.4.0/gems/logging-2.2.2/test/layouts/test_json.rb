
require File.expand_path('../setup', File.dirname(__FILE__))

module TestLogging
module TestLayouts

  class TestJson < Test::Unit::TestCase
    include LoggingTestCase

    def setup
      super
      @layout = Logging.layouts.json({})
      @levels = Logging::LEVELS
      @date_fmt = '\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{6}(Z|[+-]\d{2}:\d{2})'
      Thread.current[:name] = nil
    end

    def test_initializer
      assert_raise(ArgumentError) {
        Logging.layouts.parseable.new :style => :foo
      }
    end

    def test_format
      event = Logging::LogEvent.new('ArrayLogger', @levels['info'],
                                    'log message', false)
      format = @layout.format(event)
      assert_match %r/"timestamp":"#@date_fmt"/, format
      assert_match %r/"level":"INFO"/, format
      assert_match %r/"logger":"ArrayLogger"/, format
      assert_match %r/"message":"log message"/, format

      event.data = [1, 2, 3, 4]
      format = @layout.format(event)
      assert_match %r/"timestamp":"#@date_fmt"/, format
      assert_match %r/"level":"INFO"/, format
      assert_match %r/"logger":"ArrayLogger"/, format
      assert_match %r/"message":\[1,2,3,4\]/, format

      event.level = @levels['debug']
      event.data = 'and another message'
      format = @layout.format(event)
      assert_match %r/"timestamp":"#@date_fmt"/, format
      assert_match %r/"level":"DEBUG"/, format
      assert_match %r/"logger":"ArrayLogger"/, format
      assert_match %r/"message":"and another message"/, format

      event.logger = 'Test'
      event.level = @levels['fatal']
      event.data = Exception.new
      format = @layout.format(event)
      assert_match %r/"timestamp":"#@date_fmt"/, format
      assert_match %r/"level":"FATAL"/, format
      assert_match %r/"logger":"Test"/, format
      assert_match %r/"message":\{(?:"(?:class|message)":"Exception",?){2}\}/, format
    end

    def test_items
      assert_equal %w[timestamp level logger message], @layout.items
    end

    def test_items_eq
      event = Logging::LogEvent.new('TestLogger', @levels['info'],
                                    ['log message'], false)

      @layout.items = %w[timestamp]
      assert_equal %w[timestamp], @layout.items
      assert_match %r/\{"timestamp":"#@date_fmt"\}\n/, @layout.format(event)

      # 'foo' is not a recognized item
      assert_raise(ArgumentError) {
        @layout.items = %w[timestamp logger foo]
      }
    end

    def test_items_all
      event = Logging::LogEvent.new('TestLogger', @levels['info'],
                                    'log message', false)
      event.file = 'test_file.rb'
      event.line = 123
      event.method = 'method_name'

      @layout.items = %w[logger]
      assert_equal %Q[{"logger":"TestLogger"}\n], @layout.format(event)

      @layout.items = %w[file]
      assert_equal %Q[{"file":"test_file.rb"}\n], @layout.format(event)

      @layout.items = %w[level]
      assert_equal %Q[{"level":"INFO"}\n], @layout.format(event)

      @layout.items = %w[line]
      assert_equal %Q[{"line":123}\n], @layout.format(event)

      @layout.items = %w[message]
      assert_equal %Q[{"message":"log message"}\n], @layout.format(event)

      @layout.items = %w[method]
      assert_equal %Q[{"method":"method_name"}\n], @layout.format(event)

      @layout.items = %w[hostname]
      assert_equal %Q[{"hostname":"#{Socket.gethostname}"}\n], @layout.format(event)

      @layout.items = %w[pid]
      assert_match %r/\A\{"pid":\d+\}\n\z/, @layout.format(event)

      @layout.items = %w[millis]
      assert_match %r/\A\{"millis":\d+\}\n\z/, @layout.format(event)

      @layout.items = %w[thread_id]
      assert_match %r/\A\{"thread_id":-?\d+\}\n\z/, @layout.format(event)

      @layout.items = %w[thread]
      assert_equal %Q[{"thread":null}\n], @layout.format(event)
      Thread.current[:name] = "Main"
      assert_equal %Q[{"thread":"Main"}\n], @layout.format(event)

      @layout.items = %w[mdc]
      assert_match %r/\A\{"mdc":\{\}\}\n\z/, @layout.format(event)

      @layout.items = %w[ndc]
      assert_match %r/\A\{"ndc":\[\]\}\n\z/, @layout.format(event)
    end

    def test_mdc_output
      event = Logging::LogEvent.new('TestLogger', @levels['info'],
                                    'log message', false)
      Logging.mdc['X-Session'] = '123abc'
      Logging.mdc['Cookie'] = 'monster'

      @layout.items = %w[timestamp level logger message mdc]

      format = @layout.format(event)
      assert_match %r/"timestamp":"#@date_fmt"/, format
      assert_match %r/"level":"INFO"/, format
      assert_match %r/"logger":"TestLogger"/, format
      assert_match %r/"message":"log message"/, format
      assert_match %r/"mdc":\{(?:(?:"X-Session":"123abc"|"Cookie":"monster"),?){2}\}/, format

      Logging.mdc.delete 'Cookie'
      format = @layout.format(event)
      assert_match %r/"mdc":\{"X-Session":"123abc"\}/, format
    end

    def test_ndc_output
      event = Logging::LogEvent.new('TestLogger', @levels['info'],
                                    'log message', false)
      Logging.ndc << 'context a'
      Logging.ndc << 'context b'

      @layout.items = %w[timestamp level logger message ndc]

      format = @layout.format(event)
      assert_match %r/"timestamp":"#@date_fmt"/, format
      assert_match %r/"level":"INFO"/, format
      assert_match %r/"logger":"TestLogger"/, format
      assert_match %r/"message":"log message"/, format
      assert_match %r/"ndc":\["context a","context b"\]/, format

      Logging.ndc.pop
      format = @layout.format(event)
      assert_match %r/"ndc":\["context a"\]/, format

      Logging.ndc.pop
      format = @layout.format(event)
      assert_match %r/"ndc":\[\]/, format
    end

    def test_utc_offset
      layout = Logging.layouts.json(:items => %w[timestamp])
      event = Logging::LogEvent.new('TimestampLogger', @levels['info'], 'log message', false)
      event.time = Time.utc(2016, 12, 1, 12, 0, 0).freeze

      assert_equal %Q/{"timestamp":"2016-12-01T12:00:00.000000Z"}\n/, layout.format(event)

      layout.utc_offset = "-06:00"
      assert_equal %Q/{"timestamp":"2016-12-01T06:00:00.000000-06:00"}\n/, layout.format(event)

      layout.utc_offset = "+01:00"
      assert_equal %Q/{"timestamp":"2016-12-01T13:00:00.000000+01:00"}\n/, layout.format(event)
    end
  end  # class TestJson
end  # module TestLayouts
end  # module TestLogging

