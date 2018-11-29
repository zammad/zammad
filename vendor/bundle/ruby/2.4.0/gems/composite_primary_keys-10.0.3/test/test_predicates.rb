require File.expand_path('../abstract_unit', __FILE__)

class TestPredicates < ActiveSupport::TestCase
  fixtures :departments

  include CompositePrimaryKeys::Predicates

  def test_or
    dep = Department.arel_table

    predicates = Array.new

    3.times do |i|
      predicates << dep[:id].eq(i)
    end

    connection = ActiveRecord::Base.connection
    quoted = "#{connection.quote_table_name('departments')}.#{connection.quote_column_name('id')}"
    expected = "(#{quoted} = 0 OR #{quoted} = 1 OR #{quoted} = 2)"

    pred = cpk_or_predicate(predicates)
    assert_equal(with_quoted_identifiers(expected), pred.to_sql)
  end

  def test_or_with_many_values
    dep = Arel::Table.new(:departments)

    predicates = Array.new

    number_of_predicates = 3000 # This should really be big
    number_of_predicates.times do |i|
      predicates << dep[:id].eq(i)
    end

    connection = ActiveRecord::Base.connection
    quoted = "#{connection.quote_table_name('departments')}.#{connection.quote_column_name('id')}"
    expected_ungrouped = ((0...number_of_predicates).map { |i| "#{quoted} = #{i}" }).join(' OR ')
    expected = "(#{expected_ungrouped})"

    pred = cpk_or_predicate(predicates)
    assert_equal(with_quoted_identifiers(expected), pred.to_sql)
  end

  def test_and
    dep = Department.arel_table

    predicates = Array.new

    3.times do |i|
      predicates << dep[:id].eq(i)
    end

    connection = ActiveRecord::Base.connection
    quoted = "#{connection.quote_table_name('departments')}.#{connection.quote_column_name('id')}"
    expected = "#{quoted} = 0 AND #{quoted} = 1 AND #{quoted} = 2"

    pred = cpk_and_predicate(predicates)
    assert_equal(with_quoted_identifiers(expected), pred.to_sql)
  end
end