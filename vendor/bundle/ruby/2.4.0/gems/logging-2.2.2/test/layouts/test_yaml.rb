require 'time'
require File.expand_path('../setup', File.dirname(__FILE__))

module TestLogging
module TestLayouts

  class TestYaml < Test::Unit::TestCase
    include LoggingTestCase

    def setup
      super
      @layout = Logging.layouts.yaml({})
      @levels = Logging::LEVELS
      @date_fmt = '\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{6}(Z|[+-]\d{2}:\d{2})'
      Thread.current[:name] = nil
    end

    def test_format
      h = {
        'level' => 'INFO',
        'logger' => 'ArrayLogger',
        'message' => 'log message'
      }

      event = Logging::LogEvent.new('ArrayLogger', @levels['info'],
                                    'log message', false)
      assert_yaml_match h, @layout.format(event)

      event.data = [1, 2, 3, 4]
      h['message'] = [1,2,3,4]
      assert_yaml_match h, @layout.format(event)

      event.level = @levels['debug']
      event.data = 'and another message'
      h['level'] = 'DEBUG'
      h['message'] = 'and another message'
      assert_yaml_match h, @layout.format(event)

      event.logger = 'Test'
      event.level = @levels['fatal']
      event.data = Exception.new
      h['level'] = 'FATAL'
      h['logger'] = 'Test'
      h['message'] = {:class => 'Exception', :message => 'Exception'}
      assert_yaml_match h, @layout.format(event)
    end

    def test_items
      assert_equal %w[timestamp level logger message], @layout.items
    end

    def test_items_eq
      event = Logging::LogEvent.new('TestLogger', @levels['info'],
                                    ['log message'], false)

      @layout.items = %w[timestamp]
      assert_equal %w[timestamp], @layout.items
      assert_match %r/\A--- ?\ntimestamp: ["']#@date_fmt["']\n/, @layout.format(event)

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
      assert_match %r/\A--- ?\nlogger: TestLogger\n/, @layout.format(event)

      @layout.items = %w[file]
      assert_match %r/\A--- ?\nfile: test_file.rb\n/, @layout.format(event)

      @layout.items = %w[level]
      assert_match %r/\A--- ?\nlevel: INFO\n/, @layout.format(event)

      @layout.items = %w[line]
      assert_match %r/\A--- ?\nline: 123\n/, @layout.format(event)

      @layout.items = %w[message]
      assert_match %r/\A--- ?\nmessage: log message\n/, @layout.format(event)

      @layout.items = %w[method]
      assert_match %r/\A--- ?\nmethod: method_name\n/, @layout.format(event)

      @layout.items = %w[hostname]
      assert_match %r/\A--- ?\nhostname: #{Socket.gethostname}\n/, @layout.format(event)

      @layout.items = %w[pid]
      assert_match %r/\A--- ?\npid: \d+\n\z/, @layout.format(event)

      @layout.items = %w[millis]
      assert_match %r/\A--- ?\nmillis: \d+\n\z/, @layout.format(event)

      @layout.items = %w[thread_id]
      assert_match %r/\A--- ?\nthread_id: -?\d+\n\z/, @layout.format(event)

      @layout.items = %w[thread]
      assert_match %r/\A--- ?\nthread: ?\n/, @layout.format(event)
      Thread.current[:name] = "Main"
      assert_match %r/\A--- ?\nthread: Main\n/, @layout.format(event)

      @layout.items = %w[mdc]
      assert_match %r/\A--- ?\nmdc: \{\}\n/, @layout.format(event)

      @layout.items = %w[ndc]
      assert_match %r/\A--- ?\nndc: \[\]\n/, @layout.format(event)
    end

    def test_mdc_output
      event = Logging::LogEvent.new('TestLogger', @levels['info'],
                                    'log message', false)
      Logging.mdc['X-Session'] = '123abc'
      Logging.mdc['Cookie'] = 'monster'

      @layout.items = %w[timestamp level logger message mdc]

      format = @layout.format(event)
      assert_match %r/\nmdc: ?(?:\n  (?:X-Session: 123abc|Cookie: monster)\n?){2}/, format

      Logging.mdc.delete 'Cookie'
      format = @layout.format(event)
      assert_match %r/\nmdc: ?\n  X-Session: 123abc\n/, format
    end

    def test_ndc_output
      event = Logging::LogEvent.new('TestLogger', @levels['info'],
                                    'log message', false)
      Logging.ndc << 'context a'
      Logging.ndc << 'context b'

      @layout.items = %w[timestamp level logger message ndc]

      format = @layout.format(event)
      assert_match %r/\nndc: ?\n\s*- context a\n\s*- context b\n/, format

      Logging.ndc.pop
      format = @layout.format(event)
      assert_match %r/\nndc: ?\n\s*- context a\n/, format

      Logging.ndc.pop
      format = @layout.format(event)
      assert_match %r/\nndc: \[\]\n/, format
    end

    def test_utc_offset
      layout = Logging.layouts.yaml(:items => %w[timestamp])
      event = Logging::LogEvent.new('TimestampLogger', @levels['info'], 'log message', false)
      event.time = Time.utc(2016, 12, 1, 12, 0, 0).freeze

      assert_equal %Q{---\ntimestamp: '2016-12-01T12:00:00.000000Z'\n}, layout.format(event)

      layout.utc_offset = "-06:00"
      assert_equal %Q{---\ntimestamp: '2016-12-01T06:00:00.000000-06:00'\n}, layout.format(event)

      layout.utc_offset = "+01:00"
      assert_equal %Q{---\ntimestamp: '2016-12-01T13:00:00.000000+01:00'\n}, layout.format(event)
    end

  private

    def assert_yaml_match( expected, actual )
      actual = YAML.load(actual)

      assert_instance_of String, actual['timestamp']
      assert_instance_of Time, Time.parse(actual['timestamp'])
      assert_equal expected['level'], actual['level']
      assert_equal expected['logger'], actual['logger']
      assert_equal expected['message'], actual['message']
    end

  end  # class TestYaml
end  # module TestLayouts
end  # module TestLogging

