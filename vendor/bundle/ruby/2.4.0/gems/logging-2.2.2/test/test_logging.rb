
require File.expand_path('../setup', __FILE__)

module TestLogging

  class TestLogging < Test::Unit::TestCase
    include LoggingTestCase

    def setup
      super
      @levels = ::Logging::LEVELS
      @lnames = ::Logging::LNAMES

      @fn = File.join(TMP, 'test.log')
      @glob = File.join(TMP, '*.log')
    end

    def test_backtrace
      assert_equal true, ::Logging.backtrace

      assert_equal false, ::Logging.backtrace('off')
      assert_equal false, ::Logging.backtrace

      assert_equal true, ::Logging.backtrace('on')
      assert_equal true, ::Logging.backtrace

      assert_equal false, ::Logging.backtrace(:off)
      assert_equal false, ::Logging.backtrace

      assert_equal true, ::Logging.backtrace(:on)
      assert_equal true, ::Logging.backtrace

      assert_equal false, ::Logging.backtrace(false)
      assert_equal false, ::Logging.backtrace

      assert_equal true, ::Logging.backtrace(true)
      assert_equal true, ::Logging.backtrace

      assert_raise(ArgumentError) {::Logging.backtrace 'foo'}
    end

    def test_utc_offset
      assert_nil ::Logging.utc_offset

      ::Logging.utc_offset = 0
      assert_equal 0, ::Logging.utc_offset

      ::Logging.utc_offset = "UTC"
      assert_equal 0, ::Logging.utc_offset

      ::Logging.utc_offset = "+01:00"
      assert_equal "+01:00", ::Logging.utc_offset

      assert_raise(ArgumentError) {::Logging.utc_offset = "06:00"}
    end

    def test_cause_depth
      assert_equal ::Logging::DEFAULT_CAUSE_DEPTH, ::Logging.cause_depth

      ::Logging.cause_depth = 0
      assert_equal 0, ::Logging.cause_depth

      ::Logging.cause_depth = nil
      assert_equal ::Logging::DEFAULT_CAUSE_DEPTH, ::Logging.cause_depth

      ::Logging.cause_depth = "1024"
      assert_equal 1024, ::Logging.cause_depth

      ::Logging.cause_depth = -1
      assert_equal ::Logging::DEFAULT_CAUSE_DEPTH, ::Logging.cause_depth

      assert_raise(ArgumentError) {::Logging.cause_depth = "foo"}
    end

    def test_basepath
      assert_nil ::Logging.basepath

      ::Logging.basepath = ""
      assert_nil ::Logging.basepath

      ::Logging.basepath = "./"
      assert_equal File.expand_path("../../", __FILE__), ::Logging.basepath

      ::Logging.reset
      assert_nil ::Logging.basepath
    end

    def test_logger
      assert_raise(TypeError) {::Logging.logger []}

      logger = ::Logging.logger STDOUT
      assert_match %r/\A-?\d+\z/, logger.name
      assert_same logger, ::Logging.logger(STDOUT)

      logger.close
      assert !STDOUT.closed?

      assert !File.exist?(@fn)
      fd = File.new @fn, 'w'
      logger = ::Logging.logger fd, 2, 100
      assert_equal @fn, logger.name
      logger.debug 'this is a debug message'
      logger.warn 'this is a warning message'
      logger.error 'and now we should have over 100 bytes of data ' +
                   'in the log file'
      logger.info 'but the log file should not roll since we provided ' +
                  'a file descriptor -- not a file name'
      logger.close
      assert fd.closed?
      assert File.exist?(@fn)
      assert_equal 1, Dir.glob(@glob).length

      FileUtils.rm_f @fn
      assert !File.exist?(@fn)
      logger = ::Logging.logger @fn, 2, 100
      assert File.exist?(@fn)
      assert_equal @fn, logger.name
      logger.debug 'this is a debug message'
      logger.warn 'this is a warning message'
      logger.error 'and now we should have over 100 bytes of data ' +
                   'in the log file'
      logger.info 'but the log file should not roll since we provided ' +
                  'a file descriptor -- not a file name'
      logger.close
      assert_equal 3, Dir.glob(@glob).length
    end

    def test_init_default
      assert_equal({}, @levels)
      assert_equal([], @lnames)
      assert_same false, ::Logging.initialized?

      ::Logging::Repository.instance

      assert_equal 5, @levels.length
      assert_equal 5, @lnames.length
      assert_equal 5, ::Logging::MAX_LEVEL_LENGTH

      assert_equal 0, @levels['debug']
      assert_equal 1, @levels['info']
      assert_equal 2, @levels['warn']
      assert_equal 3, @levels['error']
      assert_equal 4, @levels['fatal']

      assert_equal 'DEBUG', @lnames[0]
      assert_equal 'INFO',  @lnames[1]
      assert_equal 'WARN',  @lnames[2]
      assert_equal 'ERROR', @lnames[3]
      assert_equal 'FATAL', @lnames[4]
    end

    def test_init_special
      assert_equal({}, @levels)
      assert_equal([], @lnames)
      assert_same false, ::Logging.initialized?

      assert_raise(ArgumentError) {::Logging.init(1, 2, 3, 4)}

      ::Logging.init :one, 'two', :THREE, 'FoUr', :sIx

      assert_equal 5, @levels.length
      assert_equal 5, @lnames.length
      assert_equal 5, ::Logging::MAX_LEVEL_LENGTH

      assert_equal 0, @levels['one']
      assert_equal 1, @levels['two']
      assert_equal 2, @levels['three']
      assert_equal 3, @levels['four']
      assert_equal 4, @levels['six']

      assert_equal 'ONE',   @lnames[0]
      assert_equal 'TWO',   @lnames[1]
      assert_equal 'THREE', @lnames[2]
      assert_equal 'FOUR',  @lnames[3]
      assert_equal 'SIX',   @lnames[4]
    end

    def test_init_all_off
      assert_equal({}, @levels)
      assert_equal([], @lnames)
      assert_same false, ::Logging.initialized?

      ::Logging.init %w(a b all c off d)

      assert_equal 4, @levels.length
      assert_equal 4, @lnames.length
      assert_equal 3, ::Logging::MAX_LEVEL_LENGTH

      assert_equal 0, @levels['a']
      assert_equal 1, @levels['b']
      assert_equal 2, @levels['c']
      assert_equal 3, @levels['d']

      assert_equal 'A', @lnames[0]
      assert_equal 'B', @lnames[1]
      assert_equal 'C', @lnames[2]
      assert_equal 'D', @lnames[3]
    end

    def test_format_as
      assert_equal false, ::Logging.const_defined?('OBJ_FORMAT')

      assert_raises(ArgumentError) {::Logging.format_as 'bob'}
      assert_raises(ArgumentError) {::Logging.format_as String}
      assert_raises(ArgumentError) {::Logging.format_as :what?}

      remove_const = lambda do |const|
        ::Logging.class_eval {remove_const const if const_defined? const}
      end

      ::Logging.format_as :string
      assert ::Logging.const_defined?('OBJ_FORMAT')
      assert_equal :string, ::Logging::OBJ_FORMAT
      remove_const[:OBJ_FORMAT]

      ::Logging.format_as :inspect
      assert ::Logging.const_defined?('OBJ_FORMAT')
      assert_equal :inspect, ::Logging::OBJ_FORMAT
      remove_const[:OBJ_FORMAT]

      ::Logging.format_as :json
      assert ::Logging.const_defined?('OBJ_FORMAT')
      assert_equal :json, ::Logging::OBJ_FORMAT
      remove_const[:OBJ_FORMAT]

      ::Logging.format_as :yaml
      assert ::Logging.const_defined?('OBJ_FORMAT')
      assert_equal :yaml, ::Logging::OBJ_FORMAT
      remove_const[:OBJ_FORMAT]

      ::Logging.format_as 'string'
      assert ::Logging.const_defined?('OBJ_FORMAT')
      assert_equal :string, ::Logging::OBJ_FORMAT
      remove_const[:OBJ_FORMAT]

      ::Logging.format_as 'inspect'
      assert ::Logging.const_defined?('OBJ_FORMAT')
      assert_equal :inspect, ::Logging::OBJ_FORMAT
      remove_const[:OBJ_FORMAT]

      ::Logging.format_as 'yaml'
      assert ::Logging.const_defined?('OBJ_FORMAT')
      assert_equal :yaml, ::Logging::OBJ_FORMAT
      remove_const[:OBJ_FORMAT]
    end

    def test_path
      path = ::Logging.path(*%w[one two three])
      assert_match %r/one\/two\/three$/, path
    end

    def test_version
      assert_match %r/\d+\.\d+\.\d+/, ::Logging.version
    end

  end  # class TestLogging
end  # module TestLogging

