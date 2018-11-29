
require File.expand_path('../setup', File.dirname(__FILE__))

module TestLogging
module TestAppenders

  class TestStringIO < Test::Unit::TestCase
    include LoggingTestCase

    def setup
      super

      @appender = Logging.appenders.string_io('test_appender')
      @sio = @appender.sio
      @levels = Logging::LEVELS
    end

    def teardown
      @appender.close
      @appender = nil
      super
    end

    def test_reopen
      assert_equal @sio.object_id, @appender.sio.object_id

      @appender.reopen
      assert @sio.closed?, 'StringIO instance is closed'
      assert_not_equal @sio.object_id, @appender.sio.object_id
    end

  end  # class TestStringIO

end  # module TestAppenders
end  # module TestLogging

