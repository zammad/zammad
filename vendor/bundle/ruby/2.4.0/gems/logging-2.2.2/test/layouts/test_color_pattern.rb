
require File.expand_path('../../setup', __FILE__)

module TestLogging
module TestLayouts

  class TestColorPattern < Test::Unit::TestCase
    include LoggingTestCase
    CS = ::Logging::ColorScheme

    def setup
      super

      ::Logging.color_scheme :levels, :levels => {
          :debug => :blue, :info => :green, :warn => :yellow, :error => :red, :fatal => :cyan
      }

      ::Logging.color_scheme :lines, :lines => {
          :debug => :blue, :info => :green, :warn => :yellow, :error => :red, :fatal => :cyan
      }, :date => :blue, :logger => :cyan

      ::Logging.color_scheme :tokens, :date => :blue, :logger => :green, :message => :magenta

      @levels = Logging::LEVELS
    end

    def test_level_coloring
      layout = Logging.layouts.pattern(:color_scheme => :levels)
      event = Logging::LogEvent.new('ArrayLogger', @levels['info'], 'log message', false)

      rgxp = Regexp.new(Regexp.escape("#{CS::GREEN}INFO #{CS::RESET}"))
      assert_match rgxp, layout.format(event)

      event.level = @levels['debug']
      rgxp = Regexp.new(Regexp.escape("#{CS::BLUE}DEBUG#{CS::RESET}"))
      assert_match rgxp, layout.format(event)

      event.level = @levels['error']
      rgxp = Regexp.new(Regexp.escape("#{CS::RED}ERROR#{CS::RESET}"))
      assert_match rgxp, layout.format(event)
    end

    def test_multiple_level_coloring
      layout = Logging.layouts.pattern(:pattern => '%.1l, %5l -- %c: %m\n', :color_scheme => :levels)
      event = Logging::LogEvent.new('ArrayLogger', @levels['info'], 'log message', false)

      rgxp = Regexp.new(Regexp.escape("#{CS::GREEN}I#{CS::RESET}, #{CS::GREEN} INFO#{CS::RESET}"))
      assert_match rgxp, layout.format(event)

      event.level = @levels['debug']
      rgxp = Regexp.new(Regexp.escape("#{CS::BLUE}D#{CS::RESET}, #{CS::BLUE}DEBUG#{CS::RESET}"))
      assert_match rgxp, layout.format(event)

      event.level = @levels['error']
      rgxp = Regexp.new(Regexp.escape("#{CS::RED}E#{CS::RESET}, #{CS::RED}ERROR#{CS::RESET}"))
      assert_match rgxp, layout.format(event)
    end

    def test_line_coloring
      layout = Logging.layouts.pattern(:color_scheme => :lines)
      event = Logging::LogEvent.new('ArrayLogger', @levels['info'], 'log message', false)

      rgxp = Regexp.new('^'+Regexp.escape(CS::GREEN)+'.*?'+Regexp.escape(CS::RESET)+'$', Regexp::MULTILINE)
      assert_match rgxp, layout.format(event)

      event.level = @levels['error']
      rgxp = Regexp.new('^'+Regexp.escape(CS::RED)+'.*?'+Regexp.escape(CS::RESET)+'$', Regexp::MULTILINE)
      assert_match rgxp, layout.format(event)

      event.level = @levels['warn']
      rgxp = Regexp.new('^'+Regexp.escape(CS::YELLOW)+'.*?'+Regexp.escape(CS::RESET)+'$', Regexp::MULTILINE)
      assert_match rgxp, layout.format(event)
    end

    def test_token_coloring
      layout = Logging.layouts.pattern(:color_scheme => :tokens)
      event = Logging::LogEvent.new('ArrayLogger', @levels['info'], 'log message', false)

      rgxp = Regexp.new(
        '^\['+Regexp.escape(CS::BLUE)+'\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}'+Regexp.escape(CS::RESET)+
        '\] INFO  -- '+Regexp.escape(CS::GREEN)+'ArrayLogger'+Regexp.escape(CS::RESET)+
        ' : '+Regexp.escape(CS::MAGENTA)+'log message'+Regexp.escape(CS::RESET)
      )
      assert_match rgxp, layout.format(event)
    end

  end  # TestColorPattern
end  # TestLayouts
end  # TestLogging

