spec_name = ENV['ADAPTER'] || 'postgresql'
require 'bundler'
Bundler.require(:default, spec_name.to_sym)

# To make debugging easier, test within this source tree versus an installed gem
$LOAD_PATH.unshift(File.expand_path('../../lib', __FILE__))
require 'composite_primary_keys'
require 'minitest/autorun'
require 'active_support/test_case'

# Require the connection spec
PROJECT_ROOT = File.expand_path(File.join(File.dirname(__FILE__), '..'))
require File.join(PROJECT_ROOT, 'test', 'connections', 'connection_spec')

spec = CompositePrimaryKeys::ConnectionSpec[spec_name]
puts "Loaded #{spec_name}"

# And now connect to the database
ActiveRecord::Base.establish_connection(spec)

if defined?(ActiveRecord::ConnectionAdapters::SQLite3Adapter)
  require 'composite_primary_keys/connection_adapters/sqlite3_adapter'
end

# Tell active record about the configuration
ActiveRecord::Base.configurations[:test] = spec

# Tell ActiveRecord where to find models
ActiveSupport::Dependencies.autoload_paths << File.join(PROJECT_ROOT, 'test', 'fixtures')

I18n.config.enforce_available_locales = true

class ActiveSupport::TestCase
  include ActiveRecord::TestFixtures

  self.fixture_path = File.dirname(__FILE__) + '/fixtures/'
  self.use_instantiated_fixtures = false
  self.use_transactional_tests = true
  self.test_order = :random

  def assert_date_from_db(expected, actual, message = nil)
    # SQL Server doesn't have a separate column type just for dates,
    # so the time is in the string and incorrectly formatted
    if current_adapter?(:SQLServerAdapter)
      assert_equal expected.strftime('%Y/%m/%d 00:00:00'), actual.strftime('%Y/%m/%d 00:00:00')
    elsif current_adapter?(:SybaseAdapter)
      assert_equal expected.to_s, actual.to_date.to_s, message
    else
      assert_equal expected.to_s, actual.to_s, message
    end
  end

  def assert_queries(num = 1)
    ActiveRecord::Base.connection.class.class_eval do
      self.query_count = 0
      alias_method :execute, :execute_with_query_counting
    end
    yield
  ensure
    ActiveRecord::Base.connection.class.class_eval do
      alias_method :execute, :execute_without_query_counting
    end
    assert_equal num, ActiveRecord::Base.connection.query_count, '#{ActiveRecord::Base.connection.query_count} instead of #{num} queries were executed.'
  end

  def assert_no_queries(&block)
    assert_queries(0, &block)
  end

  cattr_accessor :classes

  protected

  def testing_with(&block)
    classes.keys.each do |key_test|
      @key_test = key_test
      @klass_info = classes[@key_test]
      @klass, @primary_keys = @klass_info[:class], @klass_info[:primary_keys]
      order = @klass.primary_key.is_a?(String) ? @klass.primary_key : @klass.primary_key.join(',')
      @first = @klass.order(order).first
      yield
    end
  end

  def first_id
    ids = (1..@primary_keys.length).map {|num| 1}
    composite? ? ids.to_composite_ids : ids.first
  end

  def composite?
    @key_test != :single
  end

  # Oracle metadata is in all caps.
  def with_quoted_identifiers(s)
    s.gsub(/'(\w+)'/) { |m|
      if ActiveRecord::Base.configurations[:test]['adapter'] =~ /oracle/i
        m.upcase
      else
        m
      end
    }
  end
end

def current_adapter?(type)
  ActiveRecord::ConnectionAdapters.const_defined?(type) &&
    ActiveRecord::Base.connection.instance_of?(ActiveRecord::ConnectionAdapters.const_get(type))
end

ActiveRecord::Base.connection.class.class_eval do
  cattr_accessor :query_count
  alias_method :execute_without_query_counting, :execute
  def execute_with_query_counting(sql, name = nil)
    self.query_count += 1
    execute_without_query_counting(sql, name)
  end
end

ActiveRecord::Base.logger = Logger.new(ENV['CPK_LOGFILE'] || STDOUT)
