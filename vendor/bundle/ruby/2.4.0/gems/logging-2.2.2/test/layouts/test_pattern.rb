
require File.expand_path('../../setup', __FILE__)

module TestLogging
module TestLayouts

  class TestPattern < Test::Unit::TestCase
    include LoggingTestCase

    def setup
      super
      @layout = Logging.layouts.pattern({})
      @levels = Logging::LEVELS
      @date_fmt = '\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}'
      Thread.current[:name] = nil
    end

    def test_date_method
      assert_nil @layout.date_method
    end

    def test_date_method_eq
      @layout.date_method = :to_f
      assert_equal :to_f, @layout.date_method
      assert_instance_of Float, @layout.format_date(Time.now)

      @layout.date_method = 'usec'
      assert_equal 'usec', @layout.date_method
      assert_kind_of Integer, @layout.format_date(Time.now)

      @layout.date_method = :to_s
      assert_equal :to_s, @layout.date_method
      assert_instance_of String, @layout.format_date(Time.now)

      # now, even if we have defined a date_pattern, the date_method should
      # supersede the date_pattern
      @layout.date_pattern = '%Y'

      @layout.date_method = 'usec'
      assert_equal 'usec', @layout.date_method
      assert_kind_of Integer, @layout.format_date(Time.now)
    end

    def test_date_pattern
      assert_equal '%Y-%m-%dT%H:%M:%S', @layout.date_pattern
    end

    def test_date_pattern_eq
      @layout.date_pattern = '%Y'
      assert_equal '%Y', @layout.date_pattern
      assert_match %r/\A\d{4}\z/, @layout.format_date(Time.now)

      @layout.date_pattern = '%H:%M'
      assert_equal '%H:%M', @layout.date_pattern
      assert_match %r/\A\d{2}:\d{2}\z/, @layout.format_date(Time.now)
    end

    def test_format
      fmt = '\[' + @date_fmt + '\] %s -- %s : %s\n'

      event = Logging::LogEvent.new('ArrayLogger', @levels['info'],
                                    'log message', false)
      rgxp  = Regexp.new(sprintf(fmt, 'INFO ', 'ArrayLogger', 'log message'))
      assert_match rgxp, @layout.format(event)

      event.data = [1, 2, 3, 4]
      rgxp  = Regexp.new(sprintf(fmt, 'INFO ', 'ArrayLogger',
                                 Regexp.escape("<Array> #{[1,2,3,4]}")))
      assert_match rgxp, @layout.format(event)

      event.level = @levels['debug']
      event.data = 'and another message'
      rgxp  = Regexp.new(
                  sprintf(fmt, 'DEBUG', 'ArrayLogger', 'and another message'))
      assert_match rgxp, @layout.format(event)

      event.logger = 'Test'
      event.level = @levels['fatal']
      event.data = Exception.new
      rgxp  = Regexp.new(
                  sprintf(fmt, 'FATAL', 'Test', '<Exception> Exception'))
      assert_match rgxp, @layout.format(event)
    end

    def test_format_date
      rgxp = Regexp.new @date_fmt
      assert_match rgxp, @layout.format_date(Time.now)
    end

    def test_pattern
      assert_equal "[%d] %-5l -- %c : %m\n", @layout.pattern
    end

    def test_pattern_eq
      event = Logging::LogEvent.new('TestLogger', @levels['info'],
                                    ['log message'], false)

      @layout.pattern = '%d'
      assert_equal '%d', @layout.pattern
      assert_match Regexp.new(@date_fmt), @layout.format(event)
    end

    def test_pattern_all
      event = Logging::LogEvent.new('TestLogger', @levels['info'],
                                    'log message', false)
      event.file = 'test_file.rb'
      event.line = '123'
      event.method = 'method_name'

      @layout.pattern = '%c'
      assert_equal 'TestLogger', @layout.format(event)

      @layout.pattern = '%d'
      assert_match Regexp.new(@date_fmt), @layout.format(event)

      @layout.pattern = '%F'
      assert_equal 'test_file.rb', @layout.format(event)

      @layout.pattern = '%l'
      assert_equal 'INFO', @layout.format(event)

      @layout.pattern = '%L'
      assert_equal '123', @layout.format(event)

      @layout.pattern = '%m'
      assert_equal 'log message', @layout.format(event)

      @layout.pattern = '%M'
      assert_equal 'method_name', @layout.format(event)

      @layout.pattern = '%p'
      assert_match %r/\A\d+\z/, @layout.format(event)

      @layout.pattern = '%r'
      assert_match %r/\A\d+\z/, @layout.format(event)

      @layout.pattern = '%t'
      assert_match %r/\A-?\d+\z/, @layout.format(event)

      @layout.pattern = '%T'
      assert_equal "", @layout.format(event)
      Thread.current[:name] = "Main"
      assert_equal "Main", @layout.format(event)

      @layout.pattern = '%h'
      hostname = Socket.gethostname
      assert_equal hostname, @layout.format(event)

      @layout.pattern = '%%'
      assert_equal '%', @layout.format(event)

      # 'z' is not a recognized format character
      assert_raise(ArgumentError) {
        @layout.pattern = '[%d] %% %c - %l %z blah'
      }
      assert_equal '%', @layout.format(event)

      @layout.pattern = '%5l'
      assert_equal ' INFO', @layout.format(event)

      @layout.pattern = '%-5l'
      assert_equal 'INFO ', @layout.format(event)

      @layout.pattern = '%.1l, %c'
      assert_equal 'I, TestLogger', @layout.format(event)

      @layout.pattern = '%7.7m'
      assert_equal 'log mes', @layout.format(event)

      event.data = 'tim'
      assert_equal '    tim', @layout.format(event)

      @layout.pattern = '%-7.7m'
      assert_equal 'tim    ', @layout.format(event)
    end

    def test_pattern_logger_name_precision
      event = Logging::LogEvent.new('Foo', @levels['info'], 'message', false)

      @layout.pattern = '%c{2}'
      assert_equal 'Foo', @layout.format(event)

      event.logger = 'Foo::Bar::Baz::Buz'
      assert_equal 'Baz::Buz', @layout.format(event)

      assert_raise(ArgumentError) {
        @layout.pattern = '%c{0}'
      }

      @layout.pattern = '%c{foo}'
      event.logger = 'Foo::Bar'
      assert_equal 'Foo::Bar{foo}', @layout.format(event)

      @layout.pattern = '%m{42}'
      assert_equal 'message{42}', @layout.format(event)
    end

    def test_pattern_mdc
      @layout.pattern = 'S:%X{X-Session} C:%X{Cookie}'
      event = Logging::LogEvent.new('TestLogger', @levels['info'], 'log message', false)

      Logging.mdc['X-Session'] = '123abc'
      Logging.mdc['Cookie'] = 'monster'
      assert_equal 'S:123abc C:monster', @layout.format(event)

      Logging.mdc.delete 'Cookie'
      assert_equal 'S:123abc C:', @layout.format(event)

      Logging.mdc.delete 'X-Session'
      assert_equal 'S: C:', @layout.format(event)
    end

    def test_pattern_mdc_requires_key_name
      assert_raise(ArgumentError) { @layout.pattern = '%X' }
      assert_raise(ArgumentError) { @layout.pattern = '%X{}' }
    end

    def test_pattern_ndc
      @layout.pattern = '%x'
      event = Logging::LogEvent.new('TestLogger', @levels['info'], 'log message', false)

      Logging.ndc << 'context a'
      Logging.ndc << 'context b'
      assert_equal 'context a context b', @layout.format(event)

      @layout.pattern = '%x{, }'
      assert_equal 'context a, context b', @layout.format(event)

      Logging.ndc.pop
      assert_equal 'context a', @layout.format(event)
    end

    def test_utc_offset
      layout = Logging.layouts.pattern(:pattern => "%d", :utc_offset => "UTC")
      event = Logging::LogEvent.new('DateLogger', @levels['info'], 'log message', false)
      event.time = Time.utc(2016, 12, 1, 12, 0, 0).freeze

      assert_equal "2016-12-01T12:00:00", layout.format(event)

      layout.utc_offset = "-06:00"
      assert_equal "2016-12-01T06:00:00", layout.format(event)

      layout.utc_offset = "+01:00"
      assert_equal "2016-12-01T13:00:00", layout.format(event)
    end
  end  # TestBasic
end  # TestLayouts
end  # TestLogging

