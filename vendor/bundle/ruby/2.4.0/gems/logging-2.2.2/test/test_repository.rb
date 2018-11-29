
require File.expand_path('setup', File.dirname(__FILE__))

module TestLogging

  class TestRepository < Test::Unit::TestCase
    include LoggingTestCase

    def setup
      super
      @repo = ::Logging::Repository.instance
    end

    def test_instance
      assert_same @repo, ::Logging::Repository.instance
    end

    def test_aref
      root = @repo[:root]
      assert_same root, @repo[:root]

      a = []
      ::Logging::Logger.new a
      assert_same @repo['Array'], @repo[Array]
      assert_same @repo['Array'], @repo[a]

      assert_not_same @repo['Array'], @repo[:root]

      ::Logging::Logger.new 'A'
      ::Logging::Logger.new 'A::B'
      assert_not_same @repo['A'], @repo['A::B']
    end

    def test_aset
      root = @repo[:root]
      @repo[:root] = 'root'
      assert_not_same root, @repo[:root]

      assert_nil @repo['blah']
      @repo['blah'] = 'root'
      assert_equal 'root', @repo['blah']
    end

    def test_fetch
      assert @repo.has_logger?(:root)
      assert_same @repo[:root], @repo.fetch(:root)

      assert !@repo.has_logger?('A')
      assert_raise(KeyError) {@repo.fetch 'A'}

      %w(A A::B A::B::C::D A::B::C::E A::B::C::F).each do |name|
        ::Logging::Logger.new(name)
      end

      assert @repo.has_logger?('A')
      assert @repo.has_logger?('A::B')
    end

    def test_delete
      %w(A A::B A::C A::B::D).each do |name|
        ::Logging::Logger.new(name)
      end

      assert @repo.has_logger?('A')
      assert @repo.has_logger?('A::B')
      assert @repo.has_logger?('A::C')
      assert @repo.has_logger?('A::B::D')

      assert_raise(RuntimeError) {@repo.delete :root}
      assert_raise(KeyError) {@repo.delete 'Does::Not::Exist'}

      @repo.delete 'A'
      assert !@repo.has_logger?('A')
      assert_equal @repo[:root], @repo['A::B'].parent
      assert_equal @repo[:root], @repo['A::C'].parent
      assert_equal @repo['A::B'], @repo['A::B::D'].parent

      @repo.delete 'A::B'
      assert !@repo.has_logger?('A::B')
      assert_equal @repo[:root], @repo['A::B::D'].parent
    end

    def test_parent
      %w(A A::B A::B::C::D A::B::C::E A::B::C::F).each do |name|
        ::Logging::Logger.new(name)
      end

      assert_same @repo[:root], @repo.parent('A')
      assert_same @repo['A'], @repo.parent('A::B')
      assert_same @repo['A::B'], @repo.parent('A::B::C')
      assert_same @repo['A::B'], @repo.parent('A::B::C::D')
      assert_same @repo['A::B'], @repo.parent('A::B::C::E')
      assert_same @repo['A::B'], @repo.parent('A::B::C::F')

      ::Logging::Logger.new('A::B::C')

      assert_same @repo['A::B'], @repo.parent('A::B::C')
      assert_same @repo['A::B::C'], @repo.parent('A::B::C::D')
      assert_same @repo['A::B::C'], @repo.parent('A::B::C::E')
      assert_same @repo['A::B::C'], @repo.parent('A::B::C::F')

      ::Logging::Logger.new('A::B::C::E::G')

      assert_same @repo['A::B::C::E'], @repo.parent('A::B::C::E::G')

      assert_nil @repo.parent('root')
    end

    def test_children
      ::Logging::Logger.new('A')

      assert_equal [], @repo.children('A')

      ::Logging::Logger.new('A::B')
      a = %w(D E F).map {|name| ::Logging::Logger.new('A::B::C::'+name)}.sort

      assert_equal [@repo['A::B']], @repo.children('A')
      assert_equal a, @repo.children('A::B')
      assert_equal [], @repo.children('A::B::C')

      ::Logging::Logger.new('A::B::C')

      assert_equal [@repo['A::B::C']], @repo.children('A::B')
      assert_equal a, @repo.children('A::B::C')

      ::Logging::Logger.new('A::B::C::E::G')

      assert_equal a, @repo.children('A::B::C')
      assert_equal [@repo['A::B::C::E::G']], @repo.children('A::B::C::E')

      assert_equal [@repo['A'], @repo['Logging']], @repo.children('root')
    end

    def test_to_key
      assert_equal :root, @repo.to_key(:root)
      assert_equal 'Object', @repo.to_key('Object')
      assert_equal 'Object', @repo.to_key(Object)
      assert_equal 'Object', @repo.to_key(Object.new)

      assert_equal 'String', @repo.to_key(String)
      assert_equal 'Array', @repo.to_key([])

      assert_equal 'blah', @repo.to_key('blah')
      assert_equal 'blah', @repo.to_key(:blah)
    end

  end  # class TestRepository
end  # module TestLogging

