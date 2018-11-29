
require File.expand_path('setup', File.dirname(__FILE__))

module TestLogging

  class TestRootLogger < Test::Unit::TestCase
    include LoggingTestCase

    def setup
      super
      @root = ::Logging::Logger.root
    end

    def test_additive
      assert_raise(NoMethodError) {@root.additive}
    end

    def test_additive_eq
      assert_raise(NoMethodError) {@root.additive = true}
    end

    def test_level_eq
      assert_equal 0, @root.level

      assert_raise(ArgumentError) {@root.level = -1}
      assert_raise(ArgumentError) {@root.level =  6}
      assert_raise(ArgumentError) {@root.level = Object}
      assert_raise(ArgumentError) {@root.level = 'bob'}
      assert_raise(ArgumentError) {@root.level = :wtf}

      @root.level = 'INFO'
      assert_equal 1, @root.level

      @root.level = :warn
      assert_equal 2, @root.level

      @root.level = 'error'
      assert_equal 3, @root.level

      @root.level = 4
      assert_equal 4, @root.level

      @root.level = :all
      assert_equal 0, @root.level

      @root.level = 'OFF'
      assert_equal 5, @root.level

      @root.level = nil
      assert_equal 0, @root.level
    end

    def test_name
      assert_equal 'root', @root.name
    end

    def test_parent
      assert_raise(NoMethodError) {@root.parent}
    end

    def test_parent_eq
      assert_raise(NoMethodError) {@root.parent = nil}
    end

    def test_spaceship
      logs = %w(
        A  A::B  A::B::C  A::B::C::D  A::B::C::E  A::B::C::E::G  A::B::C::F
      ).map {|x| ::Logging::Logger[x]}

      logs.each do |log|
        assert_equal(-1, @root <=> log, "'root' <=> '#{log.name}'")
      end

      assert_equal 0, @root <=> @root
      assert_raise(ArgumentError) {@root <=> 'string'}
    end

  end  # class TestRootLogger
end  # module TestLogging

