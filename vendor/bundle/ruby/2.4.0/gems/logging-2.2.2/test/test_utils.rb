
require File.expand_path('setup', File.dirname(__FILE__))

module TestLogging

  class TestUtils < Test::Unit::TestCase

    def test_string_shrink
      str = 'this is the foobar string'
      len = str.length

      r = str.shrink(len + 1)
      assert_same str, r

      r = str.shrink(len)
      assert_same str, r

      r = str.shrink(len - 1)
      assert_equal 'this is the...bar string', r

      r = str.shrink(len - 10)
      assert_equal 'this i...string', r

      r = str.shrink(4)
      assert_equal 't...', r

      r = str.shrink(3)
      assert_equal '...', r

      r = str.shrink(0)
      assert_equal '...', r

      assert_raises(ArgumentError) { str.shrink(-1) }

      r = str.shrink(len - 1, '##')
      assert_equal 'this is the##obar string', r

      r = str.shrink(len - 10, '##')
      assert_equal 'this is##string', r

      r = str.shrink(4, '##')
      assert_equal 't##g', r

      r = str.shrink(3, '##')
      assert_equal 't##', r

      r = str.shrink(0, '##')
      assert_equal '##', r
    end

    def test_logger_name
      assert_equal 'Array', Array.logger_name

      # some lines are commented out for compatibility with ruby 1.9

      c = Class.new(Array)
#     assert_equal '', c.name
      assert_equal 'Array', c.logger_name

      meta = class << Array; self; end
#     assert_equal '', meta.name
      assert_equal 'Array', meta.logger_name

      m = Module.new
#     assert_equal '', m.name
      assert_equal 'anonymous', m.logger_name

      c = Class.new(::Logging::Logger)
#     assert_equal '', c.name
      assert_equal 'Logging::Logger', c.logger_name

      meta = class << ::Logging::Logger; self; end
#     assert_equal '', meta.name
      assert_equal 'Logging::Logger', meta.logger_name
    end

  end  # class TestUtils
end  # module TestLogging

