
require_relative '../setup'

module TestLogging
  module TestLayouts
    class TestNestedExceptions < Test::Unit::TestCase
      include LoggingTestCase

      def test_basic_format_obj
        err = nil
        begin
          begin
            raise ArgumentError, 'nested exception'
          rescue
            raise StandardError, 'root exception'
          end
        rescue => e
          err = e
        end

        layout = Logging.layouts.basic({})
        log = layout.format_obj(e)
        assert_not_nil log.index('<StandardError> root exception')

        if err.respond_to?(:cause)
          assert_not_nil log.index('<ArgumentError> nested exception')
          assert(log.index('<StandardError> root exception') < log.index('<ArgumentError> nested exception'))
        end
      end

      def test_cause_depth_limiting
        err = nil
        begin
          begin
            begin
              raise TypeError, 'nested exception 2'
            rescue
              raise ArgumentError, 'nested exception 1'
            end
          rescue
            raise StandardError, 'root exception'
          end
        rescue => e
          err = e
        end

        layout = Logging.layouts.basic(cause_depth: 1)
        log = layout.format_obj(e)
        assert_not_nil log.index('<StandardError> root exception')

        if err.respond_to?(:cause)
          assert_not_nil log.index('<ArgumentError> nested exception 1')
          assert_nil log.index('<TypeError> nested exception 2')
          assert_equal '--- Further #cause backtraces were omitted ---', log.split("\n\t").last
        end
      end

      def test_parseable_format_obj
        err = nil
        begin
          begin
            raise ArgumentError, 'nested exception'
          rescue
            raise StandardError, 'root exception'
          end
        rescue => e
          err = e
        end

        layout = Logging.layouts.parseable.new
        log = layout.format_obj(e)
        assert_equal 'StandardError', log[:class]
        assert_equal 'root exception', log[:message]
        assert log[:backtrace].size > 0

        if e.respond_to?(:cause)
          assert_not_nil log[:cause]

          log = log[:cause]
          assert_equal 'ArgumentError', log[:class]
          assert_equal 'nested exception', log[:message]
          assert_nil log[:cause]
          assert log[:backtrace].size > 0
        end
      end

      def test_parseable_cause_depth_limiting
        err = nil
        begin
          begin
            begin
              raise TypeError, 'nested exception 2'
            rescue
              raise ArgumentError, 'nested exception 1'
            end
          rescue
            raise StandardError, 'root exception'
          end
        rescue => e
          err = e
        end

        layout = Logging.layouts.parseable.new(cause_depth: 1)
        log = layout.format_obj(e)

        assert_equal 'StandardError', log[:class]
        assert_equal 'root exception', log[:message]
        assert log[:backtrace].size > 0

        if e.respond_to?(:cause)
          assert_not_nil log[:cause]

          log = log[:cause]
          assert_equal 'ArgumentError', log[:class]
          assert_equal 'nested exception 1', log[:message]
          assert_equal({message: "Further #cause backtraces were omitted"}, log[:cause])
          assert log[:backtrace].size > 0
        end
      end
    end
  end
end

require 'pp'
