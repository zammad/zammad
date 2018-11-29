
require File.expand_path('../setup', __FILE__)

module TestLogging

  class TestNestedDiagnosticContext < Test::Unit::TestCase
    include LoggingTestCase

    def test_push_pop
      ary = Logging.ndc.context
      assert ary.empty?

      assert_nil Logging.ndc.peek

      Logging.ndc.push 'first context'
      assert_equal 'first context', Logging.ndc.peek

      Logging.ndc << 'second'
      Logging.ndc << 'third'
      assert_equal 'third', Logging.ndc.peek
      assert_equal 3, ary.length

      assert_equal 'third', Logging.ndc.pop
      assert_equal 2, ary.length

      assert_equal 'second', Logging.ndc.pop
      assert_equal 1, ary.length

      assert_equal 'first context', Logging.ndc.pop
      assert ary.empty?
    end

    def test_push_block
      ary = Logging.ndc.context

      Logging.ndc.push('first context') do
        assert_equal 'first context', Logging.ndc.peek
      end
      assert ary.empty?

      Logging.ndc.push('first context') do
        assert_raise(ZeroDivisionError) do
          Logging.ndc.push('first context') { 1/0 }
        end
      end
      assert ary.empty?
    end

    def test_clear
      ary = Logging.ndc.context
      assert ary.empty?

      Logging.ndc << 'a' << 'b' << 'c' << 'd'
      assert_equal 'd', Logging.ndc.peek
      assert_equal 4, ary.length

      Logging.ndc.clear
      assert_nil Logging.ndc.peek
    end

    def test_thread_uniqueness
      Logging.ndc << 'first' << 'second'

      t = Thread.new {
        sleep

        Logging.ndc.clear
        assert_nil Logging.ndc.peek

        Logging.ndc << 42
        assert_equal 42, Logging.ndc.peek
      }

      Thread.pass until t.status == 'sleep'
      t.run
      t.join

      assert_equal 'second', Logging.ndc.peek
    end

    def test_thread_inheritance
      Logging.ndc << 'first' << 'second'

      t = Thread.new(Logging.ndc.context) { |ary|
        sleep

        assert_not_equal ary.object_id, Logging.ndc.context.object_id

        if Logging::INHERIT_CONTEXT
          assert_equal %w[first second], Logging.ndc.context
        else
          assert_empty Logging.ndc.context
        end
      }

      Thread.pass until t.status == 'sleep'
      Logging.ndc << 'third'

      t.run
      t.join
    end
  end  # class TestNestedDiagnosticContext
end  # module TestLogging
