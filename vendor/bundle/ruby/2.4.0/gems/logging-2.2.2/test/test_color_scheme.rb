
require File.expand_path('../setup', __FILE__)

module TestLogging

  class TestColorScheme < Test::Unit::TestCase
    include LoggingTestCase

    def setup
      super
      ::Logging.init
    end

    def test_default_color_scheme
      scheme = Logging.color_scheme :default
      assert_instance_of ::Logging::ColorScheme, scheme

      assert_equal false, scheme.include?(:debug)
      assert scheme.include?(:info)
      assert scheme.include?(:warn)
      assert scheme.include?(:error)
      assert scheme.include?(:fatal)
    end

    def test_lines_levels_exclusivity
      assert_raise(ArgumentError) { Logging.color_scheme(:error, :lines => {}, :levels => {}) }
    end

    def test_colorization
      scheme = Logging.color_scheme :default

      assert_equal "no change", scheme.color('no change', :debug)
      assert_equal "\e[32minfo is green\e[0m", scheme.color('info is green', :info)
      assert_equal "\e[37m\e[41mfatal has multiple color codes\e[0m", scheme.color('fatal has multiple color codes', :fatal)
    end

  end  # TestColorScheme
end  # TestLogging

