require File.expand_path('setup', File.dirname(__FILE__))

module TestLogging

  class TestFilter < Test::Unit::TestCase
    include LoggingTestCase

    def setup
      super

      ::Logging::init
      @lf = ::Logging::Filters::Level.new :debug, :warn
    end

    def test_level_filter_includes_selected_level
      debug_evt = event_for_level(:debug)
      warn_evt = event_for_level(:warn)
      assert_same debug_evt, @lf.allow(debug_evt), "Debug messages should be allowed"
      assert_same warn_evt, @lf.allow(warn_evt), "Warn messages should be allowed"
    end

    def test_level_filter_excludes_unselected_level
      event = event_for_level(:info)
      assert_nil @lf.allow(event), "Info messages should be disallowed"
    end

    def event_for_level(level)
      ::Logging::LogEvent.new('logger', ::Logging::LEVELS[level.to_s],
                              'message', false)
    end

  end
end
